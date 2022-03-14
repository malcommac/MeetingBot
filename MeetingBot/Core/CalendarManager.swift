//
//  CalendarManager.swift
//  NextCall
//
//  Created by daniele on 24/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import AppKit
import EventKit
import Defaults

public enum NextCallErrors: LocalizedError {
    case generic(Error)
    case permissionNotGranted
}

public class CalendarManager {
    
    // MARK: - Public Properties
    
    /// Shared instance.
    public static let shared = CalendarManager()
    
    /// Return true if user is authorized.
    public var isAuthorized: Bool {
        return (EKEventStore.authorizationStatus(for: .event) == .authorized)
    }
    
    // MARK: - Private Properties

    /// Store.
    private var store = EKEventStore()
    
    // MARK: - Initialization
    
    init() {
        
    }
    
    /// Request access to user's calendar.
    /// - Parameter completion: completion block.
    public func requestAuthorization(_ completion: ((NextCallErrors?) -> Void)? = nil) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            print("Acess granted")
            completion?(nil)

        case .denied:
            print("Access denied")
            completion?(.permissionNotGranted)

        case .notDetermined:
            store.requestAccess(to: .event, completion: {
                (granted, error) in
                
                if granted {
                    print("granted \(granted)")
                    completion?(nil)
                } else {
                    print("error \(String(describing: error))")
                    completion?( (error != nil ? .generic(error!) : nil))
                }
            })
        default:
            print("Case default")
        }
    }
    
    /// Return all calendars of the system grouped by account.
    ///
    /// - Returns: [String: [EKCalendar]]
    func allCalendars() -> [String: [EKCalendar]] {
        let allCalendars = store.calendars(for: .event)
        return Dictionary(grouping: allCalendars, by: { $0.source.title })
    }
    
    /// Return calendars with given identifiers set.
    /// - Parameter ids: ids to get.
    /// - Returns: [EKCalendar]
    func calendarsWithIDs(_ ids: [String]) -> [EKCalendar] {
        store.calendars(for: .event).filter {
            ids.contains($0.calendarIdentifier)
        }
    }
    
    /// Get the events in date range.
    ///
    /// - Parameters:
    ///   - date: from date.
    ///   - toDate: to date.
    ///   - calendars: calendars to read.
    /// - Returns: [EKEvent]
    func eventsForDate(_ date: Date, toDate: Date? = nil, inCalendars calendars: [EKCalendar]) -> [EKEvent] {
        let dayMidnight = Calendar.current.startOfDay(for: date)
        
        var endDate: Date!
        if let toDate = toDate {
            endDate = toDate.endOfDay
        } else {
            let nextDayMidnight = Calendar.current.date(byAdding: .day, value: 1, to: dayMidnight)!
            endDate = nextDayMidnight
        }
        
        let predicate = store.predicateForEvents(withStart: date, end: endDate, calendars: calendars)
        let calendarEvents = store.events(matching: predicate)
        return calendarEvents
    }
    
    /// Get the next incoming event from reference date.
    ///
    /// - Parameters:
    ///   - calendars: source calendars.
    ///   - referenceDate: reference date
    ///   - byMatching: matching type, by default is `today` only.
    ///   - minThreshold: minimum threshold for upcoming event.
    /// - Returns: EKEvent?
    func nextEventInCalendars(_ calendars: [EKCalendar],
                              fromDate referenceDate: Date,
                              byMatching: EventsToMatch = .today,
                              minThreshold: TimeInterval = 600) -> EKEvent? {
        var nextEvent: EKEvent?

        let startPeriod = Calendar.current.date(byAdding: .minute, value: 1, to: referenceDate)!
        var endPeriod: Date

        let todayMidnight = Calendar.current.startOfDay(for: referenceDate)
        switch byMatching {
        case .today:
            endPeriod = Calendar.current.date(byAdding: .day, value: 1, to: todayMidnight)!
        case .todayAndTomorrow:
            endPeriod = Calendar.current.date(byAdding: .day, value: 2, to: todayMidnight)!
        case .nextDays(let days):
            endPeriod = Calendar.current.date(byAdding: .day, value: days, to: todayMidnight)!
        }

        let predicate = store.predicateForEvents(withStart: startPeriod, end: endPeriod, calendars: calendars)
        let nextEvents = store.events(matching: predicate)
        // If the current event is still going on,
        // but the next event is closer than 10 minutes later
        // then show the next event
        for event in nextEvents {
            if event.isAllDay {
                // If is all day event we want to skip it
                continue
            }
            
            // If event is declined we want to skip it
            if let status = event.eventStatus() {
                if status == .declined {
                    continue
                }
            }
            
            if event.status == .canceled {
                // If event is canceled we want to skip it
                continue
            } else {
                if nextEvent == nil {
                    nextEvent = event
                    continue
                } else {
                    let soon = referenceDate.addingTimeInterval(minThreshold) // 10 min from now
                    if event.startDate < soon {
                        nextEvent = event
                    } else {
                        break
                    }
                }
            }
        }
        return nextEvent
    }
    
}
