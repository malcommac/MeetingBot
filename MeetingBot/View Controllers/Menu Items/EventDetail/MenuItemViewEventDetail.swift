//
//  EventMenuDetailView.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa
import EventKit
import Defaults

public class MenuItemViewEventDetail: NSView, LoadableNib {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var eventTitleLabel: NSTextField!
    @IBOutlet var eventTitle: NSTextField!
    
    @IBOutlet var eventLocationLabel: NSTextField!
    @IBOutlet var eventLocation: NSTextField!
    
    @IBOutlet var eventDescription: TextField!
    
    @IBOutlet var eventTimeLabel: NSTextField!
    @IBOutlet var eventTime: NSTextField!
    
    @IBOutlet var eventCalendarLabel: NSTextField!
    @IBOutlet var eventCalendar: NSTextField!
    
    @IBOutlet var eventAttendeesLabel: NSTextField!
    @IBOutlet var eventAttendees: NSTextField!
    
    @IBOutlet var gridTitle: NSGridView!
    @IBOutlet var gridDetails: NSGridView!

    public var event: EKEvent? {
        didSet {
            guard event != oldValue else {
                return
            }
            
            reloadData()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }
    
    private func reloadData() {
        guard let event = event else {
            return
        }
        self.wantsLayer = true
        self.contentView.wantsLayer = true

        eventTitle.stringValue = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        eventDescription.stringValue = event.cleanNotes

        eventTimeLabel.stringValue = "EventDetail_Time".l10n
        eventTime.stringValue = event.formattedTime(fromDate: Now)

        eventLocationLabel.stringValue = "EventDetail_Location".l10n
        eventLocation.stringValue = event.location ?? "No location set"

        eventCalendarLabel.stringValue = "".l10n
        eventCalendar.stringValue = event.calendar.title
        eventAttendees.stringValue = event.formattedAttendees()
        eventDescription.maxWidth = 250
        
        self.setFrameSize(self.bestSize())
    }
    
    public func bestSize() -> NSSize {
        let size = eventDescription.intrinsicContentSize.height + gridTitle.fittingSize.height + gridDetails.fittingSize.height + 40
        return NSMakeSize(330, size)
    }

    public override var allowsVibrancy: Bool {
        return true
    }
    
}

fileprivate extension EKEvent {
    
    func linksMenu(selector: Selector, target: AnyObject?) -> NSMenu {
        let menu = NSMenu(title: "Join")
        
        meetingLinks().forEach { (key, _) in
            if let serviceName = key.name {
                menu.addItem(title: serviceName, action: selector, target: target)
            }
        }
        
        return menu
    }
    
}
