//
//  NSMenu+Extensions.swift
//  NextCall
//
//  Created by daniele on 30/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa

extension NSMenuItem {
    
    public static func new(title: String, action: Selector?, keyEquivalent: String = "", target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        return item
    }
    
}

extension NSMenu {
    
    @discardableResult
    public func addItem(title: String, action: Selector?, keyEquivalent: String = "", target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem.new(title: title, action: action, keyEquivalent: keyEquivalent, target: target)
        self.addItem(item)
        return item
    }
    
}
