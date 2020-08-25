//
//  PreferencesController.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import AppKit
import EventKit
import Preferences
import Defaults

public class CalendarController: NSViewController, PreferencePane {
    
    @IBOutlet public var calendarsTable: NSTableView?
    @IBOutlet public var eventsMatch: NSPopUpButton?
    @IBOutlet public var eventsMatchDays: NSTextField?

    public let preferencePaneIdentifier = Preferences.PaneIdentifier.calendars
    public let preferencePaneTitle = "Calendars"
    public let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

    public override var nibName: NSNib.Name? { "CalendarController" }
    
    private var calendarItems = [Any]()
    private let CalendarAccountCellID = NSUserInterfaceItemIdentifier(rawValue: "CalendarAccountCell")
    private let CalendarCellID = NSUserInterfaceItemIdentifier(rawValue: "CalendarCell")
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
        reloadMatchEvents()
    }
    
    @IBAction public func didChangeMatchEvents(_ sender: Any?) {
        saveMatchedDays()
    }
    
    @IBAction public func didChangeNextDaysValue(_ sender: Any?) {
        saveMatchedDays()
    }
    
    private func saveMatchedDays() {
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
    
    private func reloadData() {
        calendarItems.removeAll()
        let allCalendars = CalendarManager.shared.allCalendars()
        
        for accountName in Array(allCalendars.keys.sorted()) {
            calendarItems.append(accountName)
            calendarItems.append(contentsOf: allCalendars[accountName]!)
        }
        
        calendarsTable?.reloadData()
    }
        
}

extension CalendarController: NSTableViewDataSource, NSTableViewDelegate {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return calendarItems.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = calendarItems[row]
        
        if let accountName = item as? String {
            let cell = tableView.makeView(withIdentifier: CalendarAccountCellID, owner: self) as? CalendarAccountCell
            cell?.account = accountName
            return cell
        }
        
        if let calendar = item as? EKCalendar {
            let cell = tableView.makeView(withIdentifier: CalendarCellID, owner: self) as? CalendarCell
            cell?.calendar = calendar
            cell?.onChangeSelection = { (calendar, isEnabled) in
                PreferenceManager.shared.setCalendar(calendar, asFavourite: isEnabled)
            }
            return cell
        }
        
         
        fatalError()
    }
    
    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
}
