//
//  PreferencesManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Foundation
import Defaults
import EventKit

extension Defaults.Keys {
    static let calendarIDs = Key<[String]>("calendarIDs", default: [])
    static let matchEvents = Key<EventsToMatch>("matchEvents", default: .today)
}

public class PreferenceManager {
    
    public static let shared = PreferenceManager()
    
    public func setCalendar(_ calendar: EKCalendar, asFavourite: Bool) {
        var selectedCalendarIDs = Set(Defaults[.calendarIDs])
        if asFavourite {
            selectedCalendarIDs.insert(calendar.calendarIdentifier)
        } else {
            selectedCalendarIDs.remove(calendar.calendarIdentifier)
        }
        
        Defaults[.calendarIDs] = Array(selectedCalendarIDs)
    }
    
    public func favouriteCalendars() -> [EKCalendar] {
        return CalendarManager.shared.calendarsWithIDs(Defaults[.calendarIDs])
    }
   
}

// MARK: - EventsToMatch

public enum EventsToMatch: Codable {
    case today
    case todayAndTomorrow
    case nextDays(Int)
    
    enum CodingKeys: String, CodingKey {
        case kind, daysCount
    }
    
    public var kindValue: Int {
        switch self {
        case .today: return 0
        case .todayAndTomorrow: return 1
        case .nextDays: return 2
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kindValue, forKey: .kind)

        if case .nextDays(let countDays) = self {
            try container.encode(countDays, forKey: .daysCount)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let daysCount = try container.decodeIfPresent(Int.self, forKey: .daysCount) ?? 0
        switch try container.decode(Int.self, forKey: .kind) {
        case 0:
            self = .today
        case 1:
            self = .todayAndTomorrow
        case 2:
            self = .nextDays(daysCount)
        default:
            fatalError()
        }
    }
}
