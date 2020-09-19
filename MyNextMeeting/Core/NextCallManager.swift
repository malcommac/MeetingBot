//
//  NextCallManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import Defaults
import EventKit
import Preferences

public class StatusBarManager {
    
    // MARK: - Public Properties

    public static let shared = StatusBarManager()
    
    // MARK: - Private Properties
    
    /// Status bar item.
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    /// Status bar main menu.
    private var statusBarMenu: NSMenu {
        return statusItem.menu ?? NSMenu()
    }
    
    /// Next upcoming event.
    private var upcomingEvent: EKEvent?
    
    /// Auto updater of the menu
    private var updater = NSBackgroundActivityScheduler(identifier: "com.spillover.periodic-updater")

    // MARK: - Windows
    
    /// About application controller.
    private let aboutAppController = AboutWindowController()
    
    /// Preferences controller.
    private let prefController = PreferencesWindowController(
        preferencePanes: [
            GeneralController(),
            CalendarController(),
        ]
    )
    
    // MARK: - Initialization
    
    public init() {
        self.statusItem.menu = NSMenu(title: "Main_Menu")
        
        update()
        configureStatusBarAutoUpdate()
    }
    
    // MARK: - Public Functions
    
    public func update() {
        // Get the favourite calendars to watch.
        let calendars = PreferenceManager.shared.favouriteCalendars()
        guard calendars.isEmpty == false else {
            setupStatusBarIconAndTitle()
            appendConfigureCalendarMenuItems()
            return
        }

        // Get the next event from calendars.
        self.upcomingEvent = CalendarManager.shared.nextEventInCalendars(calendars, fromDate: Now, byMatching: Defaults[.matchEvents])
        
        setupStatusBarIconAndTitle()
        
        appendEventsOverlookMenuItems() // Append overlook of the next events based upon settings.
        appendNextEventMenuItems() // Append next upcoming event menu
        appendApplicationMenuItems() // Append standard application menu
    }
    
    // MARK: - Private Functions (MenuBar Items Handlers)
    
    /// Configure autoupdate of the menu with a background activity at regular intervals.
    private func configureStatusBarAutoUpdate(autoInterval: TimeInterval = 30) {
        updater.repeats = true
        updater.interval = autoInterval
        updater.qualityOfService = QualityOfService.userInteractive
        updater.schedule { (completion: @escaping NSBackgroundActivityScheduler.CompletionHandler) in
            DispatchQueue.main.async {
                self.update()
                completion(NSBackgroundActivityScheduler.Result.finished)
            }
        }
    }
    
    /// Setup the icon to show in menu bar based upon the next planned event from calendars.
    private func setupStatusBarIconAndTitle() {
        let isNextEventImminent = (upcomingEvent == nil ? false : upcomingEvent!.eventInterval <= EventInterval.imminent)
        
        guard let upcomingEvent = upcomingEvent, isNextEventImminent else {
            // next event is not imminent, no alert must be shown
            setStatusBarIcon(.default)
            return
        }
        
        // Otherwise we want to show the icon and optionally the title of the event as set.
        setStatusBarIcon(.alarm)
        if Defaults[.menuBarStyle] != .icon {
            statusItem.button?.title = "      " + upcomingEvent.shortDescription(asAbbreviated: (Defaults[.menuBarStyle] == .shortTitle))
        }
    }
    
    /// Add not configured application menu items.
    private func appendConfigureCalendarMenuItems() {
        setStatusBarIcon(.notConfigured)
        
        // Add not configured calendars alert menu item
        statusBarMenu.addItem(title: "MenuItem_Configure_Calendars".l10n, action: nil, target: nil)
        statusBarMenu.addItem(NSMenuItem.separator())
        
        // Complete with application's standard menu items
        appendApplicationMenuItems()
    }
    
    /// Append the rest of the application's menus.
    private func appendApplicationMenuItems() {
        statusBarMenu.addItem(NSMenuItem.separator())

        statusBarMenu.addItem(title: "MenuItem_New_Meeting".l10n, action: #selector(createNewMeeting), target: self)
        statusBarMenu.addItem(NSMenuItem.separator())
        
        statusBarMenu.addItem(title: "MenuItem_About".l10n, action: #selector(showAboutWindow), target: self)
        statusBarMenu.addItem(title: "MenuItem_Preferences".l10n, action: #selector(showPreferencesWindow), target: self)
        statusBarMenu.addItem(title: "MenuItem_Quit".l10n, action: #selector(quitProgram), target: self)
    }
    
    /// Create events overlook menus.
    private func appendEventsOverlookMenuItems() {
        let groupsToAdd = eventsOverlookGroups()
        
        for group in groupsToAdd {
            // Title of the section
            let attributes: [NSAttributedString.Key : Any] = [
                .font: NSFont.menuBarFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            let sectionTitleMenuItem = statusBarMenu.addItem(title: group.title, action: nil, target: nil)
            sectionTitleMenuItem.attributedTitle = NSAttributedString(string: group.title.uppercased(),attributes: attributes)
            
            // Events in group
            guard group.events.isEmpty == false else {
                statusBarMenu.addItem(title: "MenuItem_NoEvents".l10n, action: nil, target: nil)
                return
            }
            
            for event in group.events {
                // Create menu for event in group alongside its submenu with details
                let eventInGroupMenuItem = statusBarMenu.addItem(title: event.title, action: nil, target: nil)
                eventInGroupMenuItem.submenu = createEventDetailMenu(event)

                // The event in group is a custom view with the preview.
                let eventMenuView = EventsMenuView(frame: CGRect(x: 0, y: 0, width: 380, height: 25))
                eventMenuView.event = event
                eventInGroupMenuItem.view = eventMenuView
            }
        }
    }
    
    /// Create a detail menu for the upcoming next event.
    private func appendNextEventMenuItems() {
        guard let upcomingEvent = upcomingEvent else {
            return
        }

        // Create next event view item
        let nextEventMenuItem = statusBarMenu.addItem(title: "Next_Event", action: nil, target: nil)
        let nextEventView = MenuSubtitleView(frame: CGRect(x: 0, y: 0, width: 380, height: 60))
        nextEventView.event = upcomingEvent
        nextEventMenuItem.view = nextEventView
        
        // Append "Join" menu items for upcoming events
        addJoinMenuItems(forEvent: upcomingEvent, intoMenu: statusBarMenu)
        statusBarMenu.addItem(NSMenuItem.separator())
        
        // Schedule a local notification to alert upon upcoming event.
        NotificationManager.shared.scheduleEventNotification(type: Defaults[.notifyEvent], forEvent: upcomingEvent)
    }
    
    /// Create new detail submenu for an event menu.
    ///
    /// - Parameter event: event.
    /// - Returns: NSMenu
    private func createEventDetailMenu(_ event: EKEvent) -> NSMenu {
        let detailMenu = NSMenu(title: event.title)
        
        // Detail View
        let item = detailMenu.addItem(title: "Event_Detail", action: nil, target: nil)
        let detailView = EventMenuDetailView(frame: CGRect(x: 0, y: 0, width: 380, height: 200))
        detailView.setFrameSize(NSMakeSize(300, detailView.fittingSize.height))
        detailView.event = event
        item.view = detailView
        
        // Join Options Menu Items
        detailMenu.addItem(NSMenuItem.separator())
        addJoinMenuItems(forEvent: event, intoMenu: detailMenu)
        
        return detailMenu
    }
    
    /// Create 'Join with...' menu items into destination menu.
    ///
    /// - Parameters:
    ///   - event: event target.
    ///   - menu: destination menu.
    private func addJoinMenuItems(forEvent event: EKEvent, intoMenu menu: NSMenu) {
        guard event.meetingLinks().isEmpty == false else {
            return
        }
        
        event.meetingLinks().forEach { (key, _) in
            let joinMenuItem = menu.addItem(title: "MenuItem_JoinWithService".l10n([key.name]), action: #selector(joinEventCall), target: self)
            joinMenuItem.representedObject = event
            joinMenuItem.tag = key.rawValue
        }
    }
    
    /// Set the new icon of the status bar.
    /// - Parameter type: type of the icon
    private func setStatusBarIcon(_ type: StatusBarIcon) {
        if let button = statusItem.button {
            if let imageView = button.subviews.first as? NSImageView  {
                imageView.image = type.icon // reuse view when available.
            } else {
                // create view if necessary
                let image = NSImageView(image: type.icon)
                image.frame = NSRect(x: 2, y: 0, width: 20, height: 20)
                button.addSubview(image)
                button.title = "   "
            }
        }
    }
    
    // MARK: - Private Functions (Data Handlers)
    
    /// Create a set of groups with events grouped by days (today, tomorrow, next x days) as set by preferences.
    /// - Returns: groups.
    private func eventsOverlookGroups() -> [EventsGroup] {
        var groups = [EventsGroup?]()
        let sourceCalendars = PreferenceManager.shared.favouriteCalendars()

        // Today
        let today = Now.startOfDay
        let todayEvents = CalendarManager.shared.eventsForDate(today, inCalendars: sourceCalendars)
        if todayEvents.count > 1 { // avoid next call and today with same data
            let todayGroup = EventsGroup(title: "Today", events: todayEvents)
            groups.append(todayGroup)
        }
        
        if Defaults[.matchEvents].kindValue >= EventsToMatch.todayAndTomorrow.kindValue {
            // We want to show Tomorrow events
            let tomorrow = today.byAddingDays(1)
            let tomorrowEvents = CalendarManager.shared.eventsForDate(tomorrow, inCalendars: sourceCalendars)
            let tomorrowGroup = EventsGroup(title: "Tomorrow", events: tomorrowEvents)
            groups.append(tomorrowGroup)
        }
        
        if case .nextDays(let count) = Defaults[.matchEvents] {
            // We want to show events in the next x days
            let fromDate = today.byAddingDays(2)
            let endDate = fromDate.byAddingDays(count - 2)
            let otherEvents = CalendarManager.shared.eventsForDate(fromDate, toDate: endDate, inCalendars: sourceCalendars)
            let otherGroup = EventsGroup(title: "Next \(count - 2) days", events: otherEvents)

            groups.append(otherGroup)
        }
        
        return groups.compactMap({ $0 }) // remove groups with no events
    }
    
    // MARK: - Actions
    
    @objc func showAboutWindow(_ sender: Any?) {
        aboutAppController.show()
    }
    
    @objc func showPreferencesWindow(_ sender: Any?) {
        prefController.show()
    }
    
    @objc func quitProgram(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func joinNextCall() {
        joinCallForEvent(upcomingEvent, withService: nil)
    }
    
    @objc func createNewMeeting(_ sender: Any?) {
        let service = CallServices(rawValue: Defaults[.defaultCallService])
        NSWorkspace.openURL(service?.newCallURL)
    }
    
    @objc func joinEventCall(_ sender: NSMenuItem) {
        guard let event = sender.representedObject as? EKEvent,
            let service = CallServices(rawValue: sender.tag) else {
            return
        }
        
        joinCallForEvent(event, withService: service)
    }
    
    @discardableResult
    private func joinCallForEvent(_ event: EKEvent?, withService service: CallServices?) -> Bool {
        guard let event = event, let fallbackService = event.meetingLinks().keys.first else {
            return false
        }
        
        let targetService = service ?? fallbackService
        guard let url = event.meetingLinks()[targetService],
            let schemaURL = url.asSchemeURLForService(targetService) else {
                return false
        }
        
        switch service {
        case .meet, .hangouts:
            if Defaults[.preferChromeWithMeet],
                let browser = Browser(URL: URL(fileURLWithPath: "/Applications/Google Chrome.app")) {
                NSWorkspace.openURL(schemaURL, withBrowser: browser.URL)
            } else {
                NSWorkspace.openURL(schemaURL)
            }
        default:
            NSWorkspace.openURL(schemaURL)
        }
        
        return true
    }
    
}

// MARK: - EventsGroup

public class EventsGroup {
    
    public let title: String
    public let events: [EKEvent]
    
    public init?(title: String, events: [EKEvent]) {
        guard events.isEmpty == false else {
            return nil
        }
        
        self.title = title
        self.events = events
    }
    
}

// MARK: - StatusBarIcon

public enum StatusBarIcon {
    case alarm
    case notConfigured
    case `default`
    
    public var icon: NSImage {
        switch self {
        case .alarm:            return NSImage(named: "statusbar_alarm")!
        case .notConfigured:    return NSImage(named: "statusbar_error")!
        case .default:          return NSImage(named: "statusbar_normal")!
        }
    }
}
