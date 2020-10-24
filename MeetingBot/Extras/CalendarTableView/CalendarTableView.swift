//
//  CalendarTableView.swift
//  NextCall
//
//  Created by daniele on 05/09/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa
import EventKit
import Defaults

public class CalendarTableView: NSTableView {

    public var onChangeSelectedCalendar: (([EKCalendar]) -> Void)?
    
    private var calendarItems = [Any]()
    private let CalendarAccountCellID = NSUserInterfaceItemIdentifier(rawValue: "CalendarAccountCell")
    private let CalendarCellID = NSUserInterfaceItemIdentifier(rawValue: "CalendarCell")
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        self.delegate = self
        self.dataSource = self
    }
    
    public override func reloadData() {
        calendarItems.removeAll()
        let allCalendars = CalendarManager.shared.allCalendars()
        
        for accountName in Array(allCalendars.keys.sorted()) {
            calendarItems.append(accountName)
            calendarItems.append(contentsOf: allCalendars[accountName]!)
        }
        
        super.reloadData()
    }
    
    private func didChangeSelectedCalendar(_ calendar: EKCalendar, enabled: Bool) {
        PreferenceManager.shared.setCalendar(calendar, asFavourite: enabled)
        
        onChangeSelectedCalendar?(PreferenceManager.shared.favouriteCalendars())
    }
}

extension CalendarTableView: NSTableViewDataSource, NSTableViewDelegate {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return calendarItems.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = calendarItems[row]
        
        // Account Name
        if let accountName = item as? String {
            let cell = tableView.makeView(withIdentifier: CalendarAccountCellID, owner: self) as? CalendarAccountCell
            cell?.account = accountName
            return cell
        }
        
        // Calendar checkbox
        if let calendar = item as? EKCalendar {
            let cell = tableView.makeView(withIdentifier: CalendarCellID, owner: self) as? CalendarCell
            cell?.calendar = calendar
            cell?.onChangeSelection = { [weak self] (calendar, isEnabled) in
                self?.didChangeSelectedCalendar(calendar, enabled: isEnabled)
            }
            return cell
        }
         
        fatalError()
    }
    
    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
}

