//
//  MenuItemViewNextCall.swift
//  NextCall
//
//  Created by daniele on 26/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa
import EventKit

public class MenuItemViewNextCall: NSView, LoadableNib {
    @IBOutlet var contentView: NSView!
    @IBOutlet var upcomingEventLabel: NSTextField!

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
    
    public func reloadData() {
        guard let event = self.event else {
            return
        }
        
        self.upcomingEventLabel.stringValue = event.title
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        if enclosingMenuItem?.isHighlighted ?? false {
            NSColor.selectedMenuItemColor.set()
            upcomingEventLabel.textColor = NSColor.labelColor
            self.bounds.fill()
        } else {
            upcomingEventLabel.textColor = NSColor.labelColor
            super.draw(dirtyRect)
        }
    }
    
}
