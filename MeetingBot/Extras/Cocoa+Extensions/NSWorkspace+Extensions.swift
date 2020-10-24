//
//  NSWorkspace+Extension.swift
//  NextCall
//
//  Created by daniele on 30/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa
import Defaults

extension NSWorkspace {
    
    static func openURL(_ URL: URL?, withBrowser appURL: URL?) {
        guard let URL = URL else {
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        
        guard let targetBrowserURL = appURL ?? PreferenceManager.shared.systemBrowser?.URL else {
            return
        }
        
        NSWorkspace.shared.open([URL],
                                withApplicationAt: targetBrowserURL,
                                configuration: configuration, completionHandler: { app, error in
                                    if error != nil {
                                        NSWorkspace.shared.open(URL)
                                    }
        })
    }
    
    static func openURL(_ URL: URL?) {
        guard let URL = URL else { return }
        let isHTTPURL = ["http", "https"].contains(URL.scheme ?? "")
        
        guard isHTTPURL == false else {
            openURL(URL, withBrowser: Defaults[.defaultBrowserURL])
            return
        }
        
        if NSWorkspace.shared.open(URL) == false {
            openURL(URL, withBrowser: Defaults[.defaultBrowserURL])
        }
    }
    
    static func openLink(_ link: URL) -> Bool {
        let result = NSWorkspace.shared.open(link)
        if result {
            NSLog("Open \(link) in default browser")
        } else {
            NSLog("Can't open \(link) in default browser")
        }
        return result
    }

    
}
