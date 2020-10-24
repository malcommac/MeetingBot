//
//  CalendarController+Cells.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import AppKit
import EventKit
import Defaults

public class CalendarAccountCell: NSTableCellView {
    
    public var account: String? {
        didSet {
            textField?.stringValue = account ?? ""
        }
    }
    
}

public class CalendarCell: NSTableCellView {
    
    public var calendar: EKCalendar? {
        didSet {
            checkbox.title = calendar?.title ?? ""
            
            let isFavourite = (calendar == nil ? false : Defaults[.calendarIDs].contains(calendar!.calendarIdentifier))
            checkbox.state = (isFavourite ? .on : .off)
        }
    }
    
    @IBOutlet public var checkbox: NSButton!
    
    public var onChangeSelection: ((EKCalendar, Bool) -> Void)?

    @IBAction func didTapCheckbox(_ sender: Any?) {
        let isActive = checkbox.state == NSControl.StateValue.on
        onChangeSelection?(calendar!, isActive)
    }
    
}
