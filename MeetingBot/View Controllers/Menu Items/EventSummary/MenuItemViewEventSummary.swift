//
//  MenuItemViewEventSummary.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
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
            eventDate.textColor = NSColor.labelColor
            self.bounds.fill()
        } else {
            eventDate.textColor = NSColor.secondaryLabelColor
            super.draw(dirtyRect)
        }
    }
    
    
}

public class TextField: NSTextField {
    
    public var maxWidth: CGFloat?
    
    public override var allowsVibrancy: Bool {
            return false
        }
    
    public override var intrinsicContentSize: NSSize {
        // Guard the cell exists and wraps
            guard let cell = self.cell, cell.wraps else {return super.intrinsicContentSize}

            // Use intrinsic width to jive with autolayout
            let width = maxWidth ?? super.intrinsicContentSize.width

            // Set the frame height to a reasonable number
            self.frame.size.height = 750.0

            // Calcuate height
            let height = cell.cellSize(forBounds: self.frame).height

        let s = NSMakeSize(width, height);
        return s
    }
    
}
