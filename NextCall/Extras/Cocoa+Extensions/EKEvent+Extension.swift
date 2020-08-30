//
//  Event.swift
//  NextCall
//
//  Created by daniele on 30/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Foundation
import EventKit

// MARK: - EKEvent Extension

extension EKEvent {
    
    /// Return the status of the event.
    ///
    /// - Returns: status.
    func eventStatus() -> EKParticipantStatus? {
        if self.hasAttendees {
            if let attendees = self.attendees { // user is not an attendee of the event.
                if let currentUser = attendees.first(where: { $0.isCurrentUser }) {
                    return currentUser.participantStatus
                }
            }
        }
        return EKParticipantStatus.unknown
    }
    
    /// Return the interval remaining to the event's start.
    public var intervalToStart: TimeInterval {
        return startDate.timeIntervalSince(Now)
    }
    
    /// Return the remaining time to the event's start.
    public var startRemainingTime: EventStartKind {
        if intervalToStart < 0 {
            let toEnd = endDate.timeIntervalSince(Now)
            return .inProgress(toEnd)
        }
        
        if intervalToStart <= 60 {
            return .now
        }
        
        if intervalToStart <= 60 * 2 {
            return .imminent
        }
        
        if intervalToStart <= 60 * 30 {
            return .soon
        }
                
        return .long
    }
    
    /// Formatted event start from reference date.
    /// - Parameter refDate: Reference date.
    /// - Returns: String.
    public func formattedTime(fromDate refDate: Date) -> String {
        guard isAllDay == false else {
            return "Event_Time_AllDay".l10n
        }
        
        switch startRemainingTime {
        case .inProgress(let remaining):
            return "Event_Time_InProgress".l10n([remaining.format(using: [.minute])])
        case .now:
            return "Event_Time_Now".l10n
        case .imminent:
            return "Event_Time_InMinutes".l10n
        case .soon:
            return "Event_Time_InMinutesLong".l10n([intervalToStart.format(using: [.minute])])
        case .long:
            return "Event_Time_StartEnd".l10n([startDate.toFormat("HH:mm"), endDate.toFormat("HH:mm")])
        }
    }
    
    public func formattedStatusTitle() -> String {
        switch startRemainingTime {
        case .inProgress(_), .now:
            return "Section_Now".l10n
        default:
            return "Section_Next".l10n
        }
    }
    
    /// Local event start date.
    var localStartDate: Date {
        startDate.toLocal
    }
    
    /// Local event date end.
    var localEndDate: Date {
        endDate.toLocal
    }
    
    /// Return clean notes.
    var cleanNotes: String {
        return notes?.cleanedNotes() ?? "Detail_NoNotes".l10n
    }
    
    /// Get the event title.
    ///
    /// - Parameter abbreviated: `true` to abbreviate and truncate title to 20 characters.
    /// - Returns: String
    func title(abbreviated: Bool) ->  String {
        let text = (abbreviated ? title.trunc(length: 20) : title)
        return "\(text ?? "") - \(formattedTime(fromDate: Now))"
    }
    
    /// Return the links of the call set for this meeting.
    /// - Returns: [CallServices: URL]
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
    
    /// Available found meeting call services.
    /// - Returns: [CallServices]
    public func meetingLinkServices() -> [CallServices] {
        return Array(meetingLinks().keys).sorted()
    }
    
    /// Return `true` if meeting urls are available.
    /// - Returns: Bool
    public func hasMeetingLinks() -> Bool {
        return meetingLinks().isEmpty == false
    }
    
}

// MARK: - EventInterval

public enum EventStartKind: Comparable {
    case inProgress(TimeInterval)
    case now
    case imminent
    case soon
    case long
    
    private var index: Int {
        switch self {
        case .inProgress(_): return 0
        case .now: return 1
        case .imminent: return 2
        case .soon: return 3
        case .long: return 4
        }
    }
    
    public static func < (lhs: EventStartKind, rhs: EventStartKind) -> Bool {
        return lhs.index < rhs.index
    }
    
}
