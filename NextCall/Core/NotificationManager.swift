//
//  NotificationManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import UserNotifications
import EventKit

public class NotificationManager {
    
    public static let shared = NotificationManager()
    
    init() {
        registerNotificationCategories()
    }
    
    public func requestNotificationAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            completion?(granted)
        }
        
    }

    func registerNotificationCategories() {
        let acceptAction = UNNotificationAction(identifier: "JOIN_ACTION",
              title: "Join",
              options: .foreground)

        let eventCategory =
              UNNotificationCategory(identifier: "EVENT",
              actions: [acceptAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([eventCategory])
    }
    
    public func showNotification(_ title: String, _ text: String){
        NSLog("Send notification: \(title) - \(text)")
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = text
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    

    func scheduleEventNotification(type: NotifyOnCall, forEvent event: EKEvent) {
        guard let interval = type.intervalToEventForNotification else {
            return
        }
        
        let now = Date()
        var timeInterval = event.startDate.timeIntervalSince(now) - interval
        guard timeInterval > 0 else {
            return
        }
        
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Call is starting soon"
        content.categoryIdentifier = "EVENT"
        content.sound = UNNotificationSound.default
        
        timeInterval = timeInterval > 0.1 ? timeInterval : 0.1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "next_event", content: content, trigger: trigger)
        center.add(request)
    }

}
