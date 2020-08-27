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

public class NextCallManager {
    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    private lazy var aboutWindow: AboutWindowController = {
       AboutWindowController()
    }()
    
    private var nextEvent: EKEvent?
    
    private var updater = NSBackgroundActivityScheduler(identifier: "com.spillover.periodic-updater")
    
    private lazy var preferencesWindowController = PreferencesWindowController(
           preferencePanes: [
               GeneralController(),
               CalendarController(),
           ]
       )
    
    public init() {
        let statusBarMenu = NSMenu(title: "NextCall Menu")
        self.statusItem.menu = statusBarMenu
        
        
        updateMenuBar()
        startMenuBarAutoUpdater()
    }
    
    private func startMenuBarAutoUpdater() {
        updater.repeats = true
        updater.interval = 30
        updater.qualityOfService = QualityOfService.userInteractive
        updater.schedule { (completion: @escaping NSBackgroundActivityScheduler.CompletionHandler) in
            DispatchQueue.main.async {
                self.updateMenuBar()
                completion(NSBackgroundActivityScheduler.Result.finished)
            }
        }
    }
    
    private func updateMenuBar() {
        let calendars = PreferenceManager.shared.favouriteCalendars()
        guard calendars.isEmpty == false else {
            return
        }
        
        let cal = CalendarManager.shared
        self.nextEvent = cal.nextEventInCalendars(calendars, fromDate: Now, byMatching: Defaults[.matchEvents])
        
        updateMenuBarTitle()
        statusItem.menu?.removeAllItems()
        addEventsGroupsInMenu(evaluateEventsGroups())
        addOtherMenuItems()
    }
    
    private func updateMenuBarTitle() {
        switch Defaults[.menuBarStyle] {
        case .icon:
            setMenuBarIcon(forAlert: nextEvent != nil)
        case .fullTitle:
            setMenuBarTitle(asAbbreviated: false)
        case .shortTitle:
            setMenuBarTitle(asAbbreviated: true)
        }
    }
    
    private func setMenuBarTitle(asAbbreviated: Bool) {
        guard let nextEvent = self.nextEvent, nextEvent.eventInterval <= EventInterval.imminent else {
            setMenuBarIcon(forAlert: false)
            return
        }
        
        if let button = statusItem.button {
            setMenuBarIcon(forAlert: true)
            button.title = "      " + nextEvent.shortDescription(asAbbreviated: asAbbreviated)
        }
    }
    
    private func setMenuBarIcon(forAlert alert: Bool) {
        if let button = statusItem.button {
            let image = NSImageView(image: NSImage(named: (alert ? "statusbar_alarm" : "statusbar_normal"))!)
            image.frame = NSRect(x: 2, y: 0, width: 20, height: 20)
            image.image?.isTemplate = true
            button.addSubview(image)
            button.title = "   "
        }
    }
    
    private func evaluateEventsGroups() -> [EventsGroup] {
        var groups = [EventsGroup?]()
        let calendars = PreferenceManager.shared.favouriteCalendars()

        // Today
        let today = Now.startOfDay
        let todayEvents = CalendarManager.shared.eventsForDate(today, inCalendars: calendars)
        if todayEvents.count > 1 { // avoid next call and today with same data
            let todayGroup = EventsGroup(title: "Today", events: todayEvents)
            groups.append(todayGroup)
        }
        
        if Defaults[.matchEvents].kindValue >= EventsToMatch.todayAndTomorrow.kindValue {
            // Tomorrow
            let tomorrow = today.byAddingDays(1)
            let tomorrowEvents = CalendarManager.shared.eventsForDate(tomorrow, inCalendars: calendars)
            let tomorrowGroup = EventsGroup(title: "Tomorrow", events: tomorrowEvents)
            groups.append(tomorrowGroup)
        }
        
        // Next Days
        if case .nextDays(let count) = Defaults[.matchEvents] {
            let fromDate = today.byAddingDays(2)
            let endDate = fromDate.byAddingDays(count - 2)
            let otherEvents = CalendarManager.shared.eventsForDate(fromDate, toDate: endDate, inCalendars: calendars)
            let otherGroup = EventsGroup(title: "Next \(count - 2) days", events: otherEvents)

            groups.append(otherGroup)
        }
        
        return groups.compactMap({ $0 })
    }
    
    private func addOtherMenuItems() {
        let menu = statusItem.menu!

        menu.addItem(NSMenuItem.separator())
        prepareNextEventSection(into: menu)
        
        menu.addItem(title: "Create New Call...", action: #selector(createNewCall), target: self)
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(title: "About", action: #selector(showAbout), target: self)
        menu.addItem(title: "Preferences...", action: #selector(showPreferencesWindow), target: self)
        menu.addItem(title: "Quit", action: #selector(exitProgram), target: self)
    }
    
    private func prepareNextEventSection(into menu: NSMenu) {
        if let nextEvent = nextEvent {
            let item = menu.addItem(title: "", action: nil, target: nil)
            let view = MenuSubtitleView(frame: CGRect(x: 0, y: 0, width: 380, height: 60))
            view.event = nextEvent
            item.view = view
            
            addJoinMenuItems(forEvent: nextEvent, intoMenu: menu)
            menu.addItem(NSMenuItem.separator())
            
            NotificationManager.shared.scheduleEventNotification(type: Defaults[.notifyEvent],
                                                                 forEvent: nextEvent)
        }
    }
    
    @objc func createNewCall(_ sender: Any?) {
        let service = CallServices(rawValue: Defaults[.defaultCallService])
        NSWorkspace.openURL(service?.newCallURL)
    }
    
    private func addEventsGroupsInMenu(_ groups: [EventsGroup]) {
        let menu = statusItem.menu
        
        for group in groups {
            let attributes: [NSAttributedString.Key : Any] = [
                .font: NSFont.menuBarFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            let groupMenu = menu?.addItem(title: group.title, action: nil, target: nil)
            groupMenu?.attributedTitle = NSAttributedString(string: group.title.uppercased(),attributes: attributes)
            
            if group.events.isEmpty {
                menu?.addItem(title: "No Events", action: nil, target: nil)
            } else {
                for event in group.events {
                    let item = menu?.addItem(title: event.title, action: nil, target: nil)
                    let view = EventsMenuView(frame: CGRect(x: 0, y: 0, width: 380, height: 25))
                    view.event = event
                    item?.view = view
                    item?.submenu = createSubmenuForEvent(event)
                }
            }
            
        }
    }
    
    @objc func showAbout(_ sender: Any?) {
        aboutWindow.show()
    }
    
    @objc func exitProgram(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func joinNextCall() {
        joinCallForEvent(nextEvent, withService: nil)
    }
    
    @objc func showPreferencesWindow(_ sender: Any?) {
        preferencesWindowController.show()
    }
    
    
    private func createSubmenuForEvent(_ event: EKEvent) -> NSMenu {
        let menu = NSMenu(title: event.title)
        
        let item = menu.addItem(title: "Detail", action: nil, target: nil)
        let view = EventMenuDetailView(frame: CGRect(x: 0, y: 0, width: 380, height: 200))
        view.event = event
        item.view = view
        
        view.setFrameSize(NSMakeSize(300, view.fittingSize.height))
        
        menu.addItem(NSMenuItem.separator())
        addJoinMenuItems(forEvent: event, intoMenu: menu)
        
        return menu
    }
    
    private func addJoinMenuItems(forEvent event: EKEvent, intoMenu menu: NSMenu) {
        if event.meetingLinks().count > 0 {
            event.meetingLinks().forEach { (key, _) in
                let item = menu.addItem(title: "Join with \(key.name)...", action: #selector(joinEventCall), target: self)
                item.representedObject = event
                item.tag = key.rawValue
            }
        }
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
