//
//  AppDelegate.swift
//  NextCall
//
//  Created by daniele on 24/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import Preferences

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: [
            GeneralController(),
            CalendarController(),
        ]
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        preferencesWindowController.show()
        
        CalendarManager.shared.requestAuthorizationIfNeeded()

               let c = PreferenceManager.shared.favouriteCalendars()
        let events = CalendarManager.shared.eventsForDate(Date().addingTimeInterval(-60 * 60 * 24), inCalendars: c)
            print(c)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

