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
    // return Date(timeIntervalSince1970: 1598250600)
    return Date()
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - App Delegate

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Authorize notifications
        NotificationManager.shared.requestNotificationAuthorization()
        
        // Authorize calendars
        CalendarManager.shared.requestAuthorization { error in
            if let error = error {
                NotificationManager.shared.showStandardNotificationMessage("Error_FailedAuthCalendar".l10n, error.localizedDescription)
                return
            }
            
            // Setup menu
            StatusBarManager.shared.setup()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - Notifications Delegate
    
    internal func userNotificationCenter(_: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case NotificationManager.MEETING_ACTION_JOIN:
            StatusBarManager.shared.joinNextCall()
        default:
            break
        }
        
        completionHandler()
    }
    
}

