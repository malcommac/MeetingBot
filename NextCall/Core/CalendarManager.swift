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
    
    func eventsForDate(_ date: Date, toDate: Date? = nil, inCalendars calendars: [EKCalendar]) -> [EKEvent] {
        let dayMidnight = Calendar.current.startOfDay(for: date)
        
        var endDate: Date!
        if let toDate = toDate {
            endDate = toDate.endOfDay
        } else {
            let nextDayMidnight = Calendar.current.date(byAdding: .day, value: 1, to: dayMidnight)!
            endDate = nextDayMidnight
        }
        
        let predicate = store.predicateForEvents(withStart: dayMidnight, end: endDate, calendars: calendars)
        let calendarEvents = store.events(matching: predicate)
        return calendarEvents
    }
    
    func nextEventInCalendars(_ calendars: [EKCalendar],
                              fromDate referenceDate: Date = Date(),
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
    
    func isApproaching(minThreshold: TimeInterval = 600) -> Bool {
        let remainingInterval = Date().timeIntervalSince(startDate)
        return remainingInterval < minThreshold
    }
    
    public var remainingInterval: TimeInterval {
        return startDate.timeIntervalSince(Now)
    }
    
    public var eventInterval: EventInterval {
        if remainingInterval < 0 {
            let toEnd = endDate.timeIntervalSince(Now)
            return .inProgress(toEnd)
        }
        
        if remainingInterval <= 60 {
            return .now
        }
        
        if remainingInterval <= 60 * 2 {
            return .imminent
        }
        
        if remainingInterval <= 60 * 30 {
            return .soon
        }
                
        return .long
    }
    
    public func formattedTime(fromDate refDate: Date) -> String {
        guard isAllDay == false else {
            return "All Day"
        }
        
        switch eventInterval {
        case .inProgress(let remaining):
            return "\(remaining.format(using: [.minute])) left"
        case .now, .imminent:
            return "Now"
        case .soon:
            return "In \(remainingInterval.format(using: [.minute]))"
        case .long:
            return "\(startDate.toFormat("HH:mm")) - \(endDate.toFormat("HH:mm"))"
        }
    }
    
    public func formattedStatusTitle() -> String {
        switch eventInterval {
        case .inProgress(_), .now:
            return "NOW"
        default:
            return "NEXT CALL"
        }
    }
    
    var localStartDate: Date {
        startDate.toLocal
    }
    
    var localEndDate: Date {
        endDate.toLocal
    }
    
    var cleanNotes: String {
        return notes?.cleanedNotes() ?? "No Notes Set"
    }
    
    var shortDescription: String {
        return "\(title ?? "") - \(formattedTime(fromDate: Now))"
    }
    
    public func meetingLinks() -> [CallServices: URL] {
        let fieldsToCheck = [title, location, notes].compactMap { $0 }
        var foundLinks = [CallServices: URL]()
        
        for field in fieldsToCheck {
            for service in CallServices.allCases {
                if let link = field.regExMatch(regex: service.regularExpression),
                    let url = URL(string: link) {
                    foundLinks[service] = url
                }
            }
        }
        
        return foundLinks        
    }
    
    public func hasMeetingLinks() -> Bool {
        return meetingLinks().isEmpty == false
    }
    
}

public enum EventInterval {
    case inProgress(TimeInterval)
    case now
    case imminent
    case soon
    case long
}
