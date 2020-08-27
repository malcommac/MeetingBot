//
//  EventMenuDetailView.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import EventKit
import Defaults

public class EventMenuDetailView: NSView, LoadableNib {
    @IBOutlet var contentView: NSView!
    @IBOutlet var eventTitle: NSTextField!
    @IBOutlet var eventLocation: NSTextField!
    @IBOutlet var eventDescription: NSTextField!
    @IBOutlet var eventTime: NSTextField!
    @IBOutlet var eventCalendar: NSTextField!

    @IBOutlet var titleHeightConstraint: NSLayoutConstraint?
    @IBOutlet var locationHeightConstraint: NSLayoutConstraint?
    @IBOutlet var descriptionHeightConstraint: NSLayoutConstraint?

    public var event: EKEvent? {
        didSet {
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
        
        eventTitle.stringValue = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        eventLocation.stringValue = event.location ?? "No location set"
        eventDescription.stringValue = event.cleanNotes
        eventTime.stringValue = event.formattedTime(fromDate: Now)
        eventCalendar.stringValue = event.calendar.title
        
        var bestSize = eventTitle.sizeThatFits(NSMakeSize(eventTitle.frame.width, 1000))
        titleHeightConstraint?.constant = bestSize.height
        
        bestSize = eventLocation.sizeThatFits(NSMakeSize(eventLocation.frame.width, 1000))
        locationHeightConstraint?.constant = bestSize.height

        bestSize = eventDescription.sizeThatFits(NSMakeSize(eventDescription.frame.width, 1000))
        descriptionHeightConstraint?.constant = bestSize.height
        
        
    }
    
    private func prepareJoinButton() {
        
       
/*
            NSRect frame = [(NSButton *)sender frame];
             NSPoint menuOrigin = [[(NSButton *)sender superview] convertPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height+40)
                                                                        toView:nil];

             NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                                  location:menuOrigin
                                             modifierFlags:NSLeftMouseDownMask // 0x100
                                                 timestamp:nil
                                              windowNumber:[[(NSButton *)sender window] windowNumber]
                                                   context:[[(NSButton *)sender window] graphicsContext]
                                               eventNumber:0
                                                clickCount:1
                                                  pressure:1];
            
             NSMenu *menu = [[NSMenu alloc] init];
             [menu insertItemWithTitle:@"add"
                                action:@selector(add:)
                         keyEquivalent:@""
                               atIndex:0];

             [NSMenu popUpContextMenu:menu withEvent:event forView:(NSButton *)sender];
*/

        }
        
        /*guard event?.hasMeetingLinks() ?? false else {
            joinButton.isEnabled = false
            return
        }
        
        let links = event?.meetingLinks()
        guard links?.count ?? 0 > 1 else {
            joinButton.menu = nil
            return
        }
        
        joinButton.isEnabled = true
        switch Defaults[.joinMultipleLinks] {
        case .showMenu:
            if let menu = event?.linksMenu(selector: #selector(joinWithService), target: self) {                
                let p = NSPoint(x: joinButton.frame.origin.x, y: joinButton.frame.origin.y - (joinButton.frame.height / 2))
                menu.popUp(positioning: nil, at: p, in: joinButton.superview)
            }
        default:
            joinButton.menu = nil
        }*/
    
    @IBAction public func didTapJoin(_ sender: NSView?) {
       
    }
    

    public override var allowsVibrancy: Bool {
        return true
    }
    
    @objc func joinWithService(_ sender: Any?) {
        
    }
    
}

fileprivate extension EKEvent {
    
    func linksMenu(selector: Selector, target: AnyObject?) -> NSMenu {
        let menu = NSMenu(title: "Join")
        
        meetingLinks().forEach { (key, _) in
            menu.addItem(title: key.name, action: selector, target: target)
        }
        
        return menu
    }
    
}
