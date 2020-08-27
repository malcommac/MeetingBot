//
//  MenuSubtitleView.swift
//  NextCall
//
//  Created by daniele on 26/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import EventKit

public class MenuSubtitleView: NSView, LoadableNib {
    @IBOutlet var contentView: NSView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var subtitleLabel: NSTextField!
    @IBOutlet var locationLabel: NSTextField!
    
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
        
        self.titleLabel.stringValue = "\(event.formattedStatusTitle()) - \(event.formattedTime(fromDate: Now))"
        self.subtitleLabel.stringValue = event.title
        self.locationLabel.stringValue = event.location ?? "No Location Set"
    }
    
//    public override func draw(_ dirtyRect: NSRect) {
//        if enclosingMenuItem?.isHighlighted ?? false {
//            NSColor.selectedMenuItemColor.set()
//            self.locationLabel.textColor = .white
//            self.titleLabel.textColor = .white
//            self.bounds.fill()
//        } else {
//            self.titleLabel.textColor = NSColor.secondaryLabelColor
//            self.locationLabel.textColor = NSColor.secondaryLabelColor
//            super.draw(dirtyRect)
//        }
//    }
    
    public override func mouseUp(with event: NSEvent) {
        if let item = self.enclosingMenuItem, let menu = item.menu {
            menu.cancelTracking()
            menu.performActionForItem(at: menu.index(of: item))
        }
    }
    
}
