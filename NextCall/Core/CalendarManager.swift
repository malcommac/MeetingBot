//
//  CalendarManager.swift
//  NextCall
//
//  Created by daniele on 24/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import AppKit
import EventKit
import Defaults

public enum NextCallErrors: LocalizedError {
    case generic(Error)
}

public class CalendarManager {
    
    public static let shared = CalendarManager()
    public private(set) var store = EKEventStore()
    
    public var isAuthorized: Bool {
        return (EKEventStore.authorizationStatus(for: .event) == .authorized)
    }
    
    init() {
        
    }
    
    public func requestAuthorizationIfNeeded(_ completion: ((NextCallErrors?) -> Void)? = nil) {
        guard isAuthorized == false else {
            completion?(nil)
            return
        }
        
        store.requestAccess(to: .event) { (isAuthorized, error) in
            guard let error = error else {
                completion?(nil)
                return
            }
            completion?(.generic(error))
        }
    }
    
    func allCalendars() -> [String: [EKCalendar]] {
        let allCalendars = store.calendars(for: .event)
        return Dictionary(grouping: allCalendars, by: { $0.source.title })
    }
    
    func calendarsWithIDs(_ ids: [String]) -> [EKCalendar] {
        store.calendars(for: .event).filter {
            ids.contains($0.calendarIdentifier)
        }
    }
    
    func eventsForDate(_ date: Date, inCalendars calendars: [EKCalendar]) -> [EKEvent] {
        let dayMidnight = Calendar.current.startOfDay(for: date)
        let nextDayMidnight = Calendar.current.date(byAdding: .day, value: 1, to: dayMidnight)!
        
        let predicate = store.predicateForEvents(withStart: dayMidnight, end: nextDayMidnight, calendars: calendars)
        let calendarEvents = store.events(matching: predicate)
        return calendarEvents
    }
    
    func nextEventInCalendars(_ calendars: [EKCalendar], fromDate referenceDate: Date = Date()) -> EKEvent? {
        var nextEvent: EKEvent?

        let startPeriod = Calendar.current.date(byAdding: .minute, value: 1, to: referenceDate)!
        var endPeriod: Date

        let todayMidnight = Calendar.current.startOfDay(for: referenceDate)
        switch Defaults[.matchEvents] {
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
            // Skip event if declined
            if event.isAllDay { continue }
            if let status = event.eventStatus() {
                if status == .declined { continue }
            }
            if event.status == .canceled {
                continue
            } else {
                if nextEvent == nil {
                    nextEvent = event
                    continue
                } else {
                    let soon = referenceDate.addingTimeInterval(600) // 10 min from now
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

extension EKEvent {
    
    func eventStatus() -> EKParticipantStatus? {
        if self.hasAttendees {
            if let attendees = self.attendees {
                if let currentUser = attendees.first(where: { $0.isCurrentUser }) {
                    return currentUser.participantStatus
                }
            }
        }
        return EKParticipantStatus.unknown
    }
    
}
