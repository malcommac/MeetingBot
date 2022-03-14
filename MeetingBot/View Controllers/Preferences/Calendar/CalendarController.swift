//
//  PreferencesController.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import AppKit
import EventKit
import Preferences
import Defaults

public class CalendarController: NSViewController, PreferencePane {
    
    // MARK: - IBOutlets

    @IBOutlet public var calendarTitleLabel: NSTextField?
    @IBOutlet public var calendarTitleSubLabel: NSTextField?
    @IBOutlet public var eventsMatchLabel: NSTextField?

    @IBOutlet public var calendarsTable: CalendarTableView?
    @IBOutlet public var eventsMatch: NSPopUpButton?
    @IBOutlet public var eventsMatchDays: NSTextField?

    // MARK: - PreferencePane

    public let preferencePaneIdentifier = Preferences.PaneIdentifier.calendars
    public let preferencePaneTitle = "Calendars"
    public let toolbarItemIcon = NSImage(named: "calendar")!
    public override var nibName: NSNib.Name? { "CalendarController" }
    
    // MARK: - Private Properties

    private var calendarItems = [Any]()
    private let CalendarAccountCellID = NSUserInterfaceItemIdentifier(rawValue: "CalendarAccountCell")
    private let CalendarCellID = NSUserInterfaceItemIdentifier(rawValue: "CalendarCell")
    
    // MARK: - Initialization
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        calendarTitleLabel?.stringValue = "Preferences_SelectCalendarsTitle".l10n
        calendarTitleSubLabel?.stringValue = "Preferences_SelectCalendarsDesc".l10n
        eventsMatchLabel?.stringValue = "Preferences_EventsMatch".l10n

        reloadCalendarTable()
        reloadMatchEvents()
    }
    
    // MARK: - IBAction
    
    @IBAction public func didChangeMatchEvents(_ sender: Any?) {
        saveMatchDaysPreference()
    }
    
    @IBAction public func didChangeNextDaysValue(_ sender: Any?) {
        saveMatchDaysPreference()
    }
    
    @IBAction public func reloadData(_ sender: Any?) {
        reloadCalendarTable()
    }
    
    // MARK: - Private Funtions
    
    private func saveMatchDaysPreference() {
        switch eventsMatch?.selectedTag() {
        case EventsToMatch.today.kindValue:
            Defaults[.matchEvents] = .today
            
        case EventsToMatch.todayAndTomorrow.kindValue:
            Defaults[.matchEvents] = .todayAndTomorrow

        case EventsToMatch.nextDays(0).kindValue:
            let countDays = Int(eventsMatchDays!.stringValue)!
            Defaults[.matchEvents] = .nextDays(countDays)

        default:
            break
        }
        
        reloadMatchEvents()
        StatusBarManager.shared.update()
    }
    
    private func reloadMatchEvents() {
        eventsMatch?.selectItem(withTag: Defaults[.matchEvents].kindValue)
        if case .nextDays(let countDays) = Defaults[.matchEvents] {
            eventsMatchDays?.isHidden = false
            eventsMatchDays?.stringValue = String(countDays)
        } else {
            eventsMatchDays?.isHidden = true
            eventsMatchDays?.stringValue = "0"
        }
    }
    
    private func reloadCalendarTable() {
        calendarItems.removeAll()
        let allCalendars = CalendarManager.shared.allCalendars()
        
        for accountName in Array(allCalendars.keys.sorted()) {
            calendarItems.append(accountName)
            calendarItems.append(contentsOf: allCalendars[accountName]!)
        }
        
        calendarsTable?.onChangeSelectedCalendar = { _ in
            StatusBarManager.shared.update()
        }
        
        calendarsTable?.reloadData()
    }
    
}
