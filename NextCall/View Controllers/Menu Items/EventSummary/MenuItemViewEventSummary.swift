//
//  MenuItemViewEventSummary.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import AppKit
import EventKit

class MenuItemViewEventSummary: NSView, LoadableNib {
    
    public var event: EKEvent? {
        didSet {
            reloadData()
        }
    }

    @IBOutlet var contentView: NSView!
    @IBOutlet var eventLabel: NSTextField!
    @IBOutlet var eventDate: NSTextField!

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
        
        eventLabel.stringValue = event.title
        eventDate.stringValue = event.formattedTime(fromDate: Now)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if enclosingMenuItem?.isHighlighted ?? false {
            NSColor.selectedMenuItemColor.set()
            eventDate.textColor = .white
            self.bounds.fill()
        } else {
            eventDate.textColor = NSColor.secondaryLabelColor
            super.draw(dirtyRect)
        }
    }
    
    
}

public class TextField: NSTextField {
    
    public override var allowsVibrancy: Bool {
            return false
        }
    
}
