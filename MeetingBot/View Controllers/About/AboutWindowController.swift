//
//  AboutWindowController.swift
//  NextCall
//
//  Created by daniele on 27/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa

public class AboutWindowController: NSWindowController {
        
    @IBOutlet public var appTitleLabel: NSTextField?
    @IBOutlet public var appTaglineLabel: NSTextField?
    @IBOutlet public var appVersionLabel: NSTextField?

    public convenience init() {
        self.init(windowNibName: "About")
        self.loadWindow()

        appTaglineLabel?.stringValue = "App_Tagline".l10n
        appVersionLabel?.stringValue = "App_Version".l10n([version()])
    }
    
    public func show() {
        self.window?.level = .modalPanel
        self.showWindow(nil)
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.center()
    }
    
    @IBAction public func support(_ sender: Any?) {
        NSWorkspace.openURL(URL(string: "App_Mail".l10n)!)
    }
    
    @IBAction public func website(_ sender: Any?) {
        NSWorkspace.openURL(URL(string: "App_URL".l10n)!)
    }
    
    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version) build \(build)"
    }
    
}
