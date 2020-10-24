//
//  NotificationManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa
import UserNotifications
import EventKit

public class NotificationManager {
    
    // MARK: - Private Properties

    private static let MEETING_REMINDER_ID = "MEETING_REMINDER"
    
    // MARK: - Public Properties

    public static let MEETING_ACTION_JOIN = "JOIN_MEETING"
    
    /// Shared instance.
    public static let shared = NotificationManager()
    
    // MARK: - Initialization

    private init() {
        registerNotificationCategories()
    }
    
    public private(set) var isAuthorized = false
    
    public func isAuthorized(_ completion: @escaping ((Bool) -> Void)) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAuthorized = settings.authorizationStatus == .authorized
                completion(self.isAuthorized)
            }
        }
    }
    
    
    // MARK: - Public Functions
    
    /// Request authorization for push notifications.
    /// - Parameter completion: completion block.
    public func requestNotificationAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            DispatchQueue.main.async {
                self.registerNotificationCategories()
                completion?(granted)
            }
        }
        
    }
    
    /// Show standard read-only notification message.
    /// - Parameters:
    ///   - title: title of the message.
    ///   - text: text of the message.
    public func showStandardNotificationMessage(_ title: String, _ text: String){
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = text
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    
    /// Schedule a meeting reminder notification.
    /// - Parameters:
    ///   - type: type of notification.
    ///   - event: target event.
    func scheduleEventNotification(type: NotifyOnCall, forEvent event: EKEvent) {
        guard let interval = type.intervalToEventForNotification else {
            return
        }
        
        requestNotificationAuthorization()
        
        let now = Date()
        var timeInterval = event.startDate.timeIntervalSince(now) - interval
        guard timeInterval > 0 else {
            return
        }
        
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Notification_CallIsStarting".l10n
        content.categoryIdentifier = NotificationManager.MEETING_REMINDER_ID
        content.sound = UNNotificationSound.default
        
        timeInterval = timeInterval > 0.1 ? timeInterval : 0.1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "next_event", content: content, trigger: trigger)
        center.add(request)
    }
    
    // MARK: - Private Functions
    
    /// Register categories of push notifications.
    private func registerNotificationCategories() {
        let joinButton = UNNotificationAction(identifier: NotificationManager.MEETING_ACTION_JOIN,
                                                title: "Notification_Button_Join".l10n,
                                                options: .foreground)
        
        let eventCategory =
            UNNotificationCategory(identifier: NotificationManager.MEETING_REMINDER_ID,
                                   actions: [joinButton],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([eventCategory])
    }

}
