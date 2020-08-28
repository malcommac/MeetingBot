//
//  AppDelegate.swift
//  NextCall
//
//  Created by daniele on 24/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import Preferences
import UserNotifications

public var Now: Date {
    return Date(timeIntervalSince1970: 1598250600)
   // return Date()
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    let manager = NextCallManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        CalendarManager.shared.requestAuthorizationIfNeeded()
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    internal func userNotificationCenter(_: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "JOIN_ACTION":
            manager.joinNextCall()
        default:
            break
        }
        
        completionHandler()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

