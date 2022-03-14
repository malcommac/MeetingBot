//
//  NextCallManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa
import Defaults
import EventKit
import Preferences

public class StatusBarManager: NSObject, NSMenuDelegate {
    
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
    
    private var isMenuOpened: Bool = false
    
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
            SpeedDialController()
        ]
    )
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        self.statusItem.menu = NSMenu(title: "Main_Menu")
        self.statusItem.menu?.delegate = self
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        isMenuOpened = true
    }
    
    public func menuDidClose(_ menu: NSMenu) {
        isMenuOpened = false
    }
    
    // MARK: - Public Functions
    
    /// Call on startup.
    public func setup() {
        update()
        configureStatusBarAutoUpdate()
    }
    
    public func update() {
        statusBarMenu.removeAllItems()
        
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
        

        let hasUpcomingEvent = appendNextEventMenuItems() // Append next upcoming event menu
        let hasOtherEvents = appendEventsOverlookMenuItems() // Append overlook of the next events based upon settings.
        
        if hasUpcomingEvent || hasOtherEvents {
            let attributes: [NSAttributedString.Key : Any] = [
                .font: NSFont.menuBarFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            let sectionTitleMenuItem = NSMenuItem(title: "NEXT_EVENTS", action: nil, keyEquivalent: "")
            sectionTitleMenuItem.attributedTitle = NSAttributedString(string: "Menu_NextEvents".l10n, attributes: attributes)
            statusBarMenu.insertItem(sectionTitleMenuItem, at: 0)
        }
        
        appendSpeedDialMenuItems()
        appendApplicationMenuItems() // Append standard application menu
    }
    
    // MARK: - Private Functions (MenuBar Items Handlers)
    
    /// Configure autoupdate of the menu with a background activity at regular intervals.
    private func configureStatusBarAutoUpdate(autoInterval: TimeInterval = 15) {
        updater.repeats = true
        updater.interval = autoInterval
        updater.qualityOfService = QualityOfService.userInteractive
        updater.schedule { (completion: @escaping NSBackgroundActivityScheduler.CompletionHandler) in
            guard self.isMenuOpened == false else {
                debugPrint("Ignored because menu is opened")
                completion(NSBackgroundActivityScheduler.Result.finished)
                return
            }
            
            DispatchQueue.main.async {
                self.update()
                debugPrint("Status bar updated!")
                completion(NSBackgroundActivityScheduler.Result.finished)
            }
        }
    }
    
    /// Setup the icon to show in menu bar based upon the next planned event from calendars.
    private func setupStatusBarIconAndTitle() {
        let isNextEventImminent = (upcomingEvent == nil ? false : upcomingEvent!.startRemainingTime <= EventStartKind.imminent)
        
        if isNextEventImminent {
            setStatusBarIcon(.alarm)
        } else {
            setStatusBarIcon(.default)
        }
        
        switch Defaults[.menuBarStyle] {
        case .icon:
            break

        case .iconAndCountdown:
            if let upcomingEvent = upcomingEvent {
                statusItem.button?.title = "      " + upcomingEvent.formattedRemainingTime()
            }
            
        case .fullTitle, .shortTitle:
            if let upcomingEvent = upcomingEvent {
                statusItem.button?.title = "      " + upcomingEvent.title(abbreviated: (Defaults[.menuBarStyle] == .shortTitle))
            }
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
    
    private func appendSpeedDialMenuItems() {
        statusBarMenu.addItem(NSMenuItem.separator())

        let items = PreferenceManager.shared.speedDialItems()
        guard items.isEmpty == false else {
            return
        }
        
        // Title
        let attributes: [NSAttributedString.Key : Any] = [
            .font: NSFont.menuBarFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let sectionTitleMenuItem = NSMenuItem(title: "SPEED_DIAL", action: nil, keyEquivalent: "")
        sectionTitleMenuItem.attributedTitle = NSAttributedString(string: "Menu_SpeedDial".l10n,attributes: attributes)
        statusBarMenu.addItem(sectionTitleMenuItem)
         
        // Speed Items
        for speedDialItem in items {
            let speedDialMenuItem = statusBarMenu.addItem(title: speedDialItem.title, action: #selector(launchSpeedDialURL), target: self)
            speedDialMenuItem.representedObject = speedDialItem
        }
    }
    
    /// Append the rest of the application's menus.
    private func appendApplicationMenuItems() {
        statusBarMenu.addItem(NSMenuItem.separator())

        let newMeeting = statusBarMenu.addItem(title: "MenuItem_New_Meeting".l10n, action: nil, target: self)
        let newServiceMenu = NSMenu(title: "")
        for callService in CallServices.allCases.filter({ $0.newCallURL != nil }) {
            let serviceMenuItem = newServiceMenu.addItem(withTitle: callService.name!, action: #selector(createNewMeeting), keyEquivalent: "")
            serviceMenuItem.target = self
            serviceMenuItem.representedObject = callService
        }
        newMeeting.submenu = newServiceMenu
        
        statusBarMenu.addItem(title: "MenuItem_Preferences".l10n, action: #selector(showPreferencesWindow), target: self)
        statusBarMenu.addItem(title: "MenuItem_About".l10n, action: #selector(showAboutWindow), target: self)
        statusBarMenu.addItem(title: "MenuItem_Quit".l10n, action: #selector(quitProgram), target: self)
    }
    
    /// Create events overlook menus.
    private func appendEventsOverlookMenuItems() -> Bool {
        let groupsToAdd = eventsOverlookGroups()
        
        for group in groupsToAdd {
            for event in group.events {
                // Create menu for event in group alongside its submenu with details
                let eventInGroupMenuItem = statusBarMenu.addItem(title: event.title, action: nil, target: nil)
                eventInGroupMenuItem.submenu = createEventDetailMenu(event)

                // The event in group is a custom view with the preview.
                let eventMenuView = MenuItemViewEventSummary(frame: CGRect(x: 0, y: 0, width: 380, height: 25))
                eventMenuView.event = event
                eventInGroupMenuItem.view = eventMenuView
            }
        }
        
        return groupsToAdd.count > 0
    }
    
    /// Create a detail menu for the upcoming next event.
    private func appendNextEventMenuItems() -> Bool {
        guard let upcomingEvent = upcomingEvent else {
            return false
        }

        // Create next event view item
        let nextEventMenuItem = statusBarMenu.addItem(title: "Next_Event", action: nil, target: nil)
        let nextEventView = MenuItemViewNextCall(frame: CGRect(x: 0, y: 0, width: 380, height: 25))
        nextEventView.event = upcomingEvent
        nextEventMenuItem.view = nextEventView
        nextEventMenuItem.submenu = createEventDetailMenu(upcomingEvent)
        
        // Schedule a local notification to alert upon upcoming event.
        NotificationManager.shared.scheduleEventNotification(type: Defaults[.notifyEvent], forEvent: upcomingEvent)
        
        return true
    }
    
    /// Create new detail submenu for an event menu.
    ///
    /// - Parameter event: event.
    /// - Returns: NSMenu
    private func createEventDetailMenu(_ event: EKEvent) -> NSMenu {
        let detailMenu = NSMenu(title: event.title)
        
        // Detail View
        let item = detailMenu.addItem(title: "Event_Detail", action: nil, target: nil)
        let detailView = MenuItemViewEventDetail(frame: .zero)
        detailView.event = event
        item.view = detailView
        
        detailMenu.addItem(NSMenuItem.separator())
        addAttendeeMenuItem(forEvent: event, intoMenu: detailMenu)
        detailMenu.addItem(NSMenuItem.separator())
        addJoinMenuItems(forEvent: event, intoMenu: detailMenu)

        return detailMenu
    }
    
    private func addAttendeeMenuItem(forEvent event: EKEvent, intoMenu menu: NSMenu) {
        guard event.hasAttendees else {
            return
        }
        
        let listAttendees = event.attendeesStats().list
        let attendeeMenuItem = menu.addItem(title: "\(listAttendees.count) Attendees", action: nil, target: nil)

        let attendeeMenu = NSMenu(title: "Attendees")
        for attendee in listAttendees {
            let item = attendeeMenu.addItem(title: "", action: nil, target: nil)
            item.attributedTitle = attendee.formattedName
        }
        attendeeMenuItem.submenu = attendeeMenu
    }
    
    /// Create 'Join with...' menu items into destination menu.
    ///
    /// - Parameters:
    ///   - event: event target.
    ///   - menu: destination menu.
    private func addJoinMenuItems(forEvent event: EKEvent, intoMenu menu: NSMenu) {
        let foundServices = event.meetingLinkServices()
        guard foundServices.isEmpty == false else {
            menu.addItem(title: "Menu_NoURL".l10n, action: nil, target: nil)
            return
        }
        
        foundServices.forEach { service in
            if let serviceName = service.name {
                let joinMenuItem = menu.addItem(title: "MenuItem_JoinWithService".l10n([serviceName]),
                                                action: #selector(joinEventCall),
                                                target: self)
                joinMenuItem.image = service.icon
                joinMenuItem.representedObject = event
                joinMenuItem.tag = service.rawValue
            }
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
            }
            button.title = "   "
        }
    }
    
    // MARK: - Private Functions (Data Handlers)
    
    /// Create a set of groups with events grouped by days (today, tomorrow, next x days) as set by preferences.
    /// - Returns: groups.
    private func eventsOverlookGroups() -> [EventsGroup] {
        var groups = [EventsGroup?]()
        let sourceCalendars = PreferenceManager.shared.favouriteCalendars()

        // Today
        let today = Now.addingTimeInterval(-(5*60))
        let todayEvents = CalendarManager.shared.eventsForDate(today, inCalendars: sourceCalendars).filter {
            $0 != upcomingEvent
        }
        if todayEvents.count > 0 { // avoid next call and today with same data
            let todayGroup = EventsGroup(title: "Next Events", events: todayEvents)
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
    
    @objc func launchSpeedDialURL(_ sender: NSMenuItem) {
        guard let speedDialItem = sender.representedObject as? SpeedDialItem,
              let url = speedDialItem.url else {
            return
        }
        
        NSWorkspace.openURL(url)
    }
    
    @objc func createNewMeeting(_ sender: NSMenuItem) {
        guard let service = sender.representedObject as? CallServices,
              let serviceURL = service.newCallURL else {
            return
        }
        
        NSWorkspace.openURL(serviceURL)
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
