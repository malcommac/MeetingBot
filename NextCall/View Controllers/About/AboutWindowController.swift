//
//  AboutWindowController.swift
//  NextCall
//
//  Created by daniele on 27/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa

public class AboutWindowController: NSWindowController {
        
    public convenience init() {
        self.init(windowNibName: "About")
        self.loadWindow()
    }
    
    public func show() {
        self.showWindow(nil)
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.center()
    }
    
    @IBAction public func support(_ sender: Any?) {
        
    }
    
    @IBAction public func website(_ sender: Any?) {
        NSWorkspace.openURL(URL(string: "https://www.danielemargutti.com")!)
    }
    
}
