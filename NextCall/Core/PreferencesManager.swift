//
//  PreferencesManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Defaults
import EventKit
import AppKit

// MARK: - Preferences Keys

extension Defaults.Keys {
    static let calendarIDs = Key<[String]>("calendarIDs", default: [])
    static let matchEvents = Key<EventsToMatch>("matchEvents", default: .today)
    static let defaultBrowserURL = Key<URL?>("defaultBrowserURL")
    static let preferChromeWithMeet = Key<Bool>("preferChromeWithMeet", default: true)
    static let defaultCallService = Key<Int>("defaultCallService", default: CallServices.zoom.rawValue)
    static let notifyEvent = Key<NotifyOnCall>("notifyEvent", default: .atTimeOfEvent)
    static let menuBarStyle = Key<MenuBarStyle>("menuBarStyle", default: .icon)
}

// MARK: - PreferenceManager

public class PreferenceManager {
    
    /// Shared instance.
    public static let shared = PreferenceManager()
    
    /// Save calendars to monitor.
    /// - Parameters:
    ///   - calendar: calendar.
    ///   - asFavourite: `true` to enable watching calendar, `false` to remove it from monitored calendars.
    public func setCalendar(_ calendar: EKCalendar, asFavourite: Bool) {
        var selectedCalendarIDs = Set(Defaults[.calendarIDs])
        if asFavourite {
            selectedCalendarIDs.insert(calendar.calendarIdentifier)
        } else {
            selectedCalendarIDs.remove(calendar.calendarIdentifier)
        }
        
        Defaults[.calendarIDs] = Array(selectedCalendarIDs)
    }
    
    /// Return favourite calendars.
    /// - Returns: [EKCalendar]
    public func favouriteCalendars() -> [EKCalendar] {
        let calendarIDs = Defaults[.calendarIDs]
        print("Calendars: \(calendarIDs)")
        return CalendarManager.shared.calendarsWithIDs(calendarIDs)
    }
    
    /// Return the list of installed browsers.
    /// - Returns: [Browser]
    public func installedBrowsers() -> [Browser] {
        let allURLs = LSCopyApplicationURLsForURL(URL(string: "https:")! as CFURL, .all)?.takeRetainedValue() as? [URL]
        return allURLs?.compactMap { Browser(URL: $0) } ?? []
    }
    
    /// Return system set browser.
    public lazy var systemBrowser: Browser? = {
        guard let url = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "http://www.apple.com")!) else {
            return nil
        }
        
        return Browser(URL: url)
    }()
   
}

// MARK: - MenuBarStyle (Preference Structure)

public enum MenuBarStyle: Int, Codable, CaseIterable {
    case icon
    case fullTitle
    case shortTitle
    
    public var title: String {
        switch self {
        case .icon: return "Icon"
        case .fullTitle: return "Next Event Title"
        case .shortTitle: return "Next Event Abbreviated Title"
        }
    }
}

// MARK: - Browser (Preference Structure)

public class Browser {
    public var URL: URL
    
    public lazy var name: String = {
        guard let displayName = Bundle(url: URL)?.infoDictionary?["CFBundleDisplayName"] as? String else {
            return (URL.lastPathComponent as NSString).deletingPathExtension
        }

        return "\(displayName) \(isSystemDefault ? "(Default)" : "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }()
    
    public var isSystemDefault: Bool {
        return URL == PreferenceManager.shared.systemBrowser?.URL
    }
    
    public lazy var icon: NSImage? = {
        return NSWorkspace.shared.icon(forFile: URL.path)
    }()
    
    public init?(URL: URL) {
        guard FileManager.default.fileExists(atPath: URL.path) else {
            return nil
        }
        
        self.URL = URL
    }
    
}

// MARK: - NotifyOnCall (Preference Structure)

public enum NotifyOnCall: Int, Codable, CaseIterable {
    case never
    case asApproaching
    case atTimeOfEvent
    
    public var name: String {
        switch self {
        case .never: return "Never"
        case .asApproaching: return "5 minutes before"
        case .atTimeOfEvent: return "At the time of the event"
        }
    }
    
    public var intervalToEventForNotification: TimeInterval? {
        switch self {
        case .never:
            return nil
        case .asApproaching:
            return 5 * 60
        case .atTimeOfEvent:
            return 5
        }
    }
}

// MARK: - CallServices (Preference Structure)

public enum CallServices: Int, Codable, CaseIterable, Comparable {
    public static func < (lhs: CallServices, rhs: CallServices) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case zoom
    case meet
    case teams
    case hangouts
    case webex
    
    public var name: String {
        switch self {
        case .zoom: return "Zoom"
        case .meet: return "Google Meet"
        case .teams: return "Microsoft Teams"
        case .hangouts: return "Hangout"
        case .webex: return "Webex"
        }
    }
    
    public var regularExpression: NSRegularExpression {
        switch self {
        case .meet:
            return try! NSRegularExpression(pattern: #"https://meet.google.com/[a-z-]+"#)
        case .hangouts:
            return try! NSRegularExpression(pattern: #"https://hangouts.google.com.*"#)
        case .zoom:
            return try! NSRegularExpression(pattern: #"https://([a-z0-9.]+)?zoom.us/j/[a-zA-Z0-9?&=]+"#)
        case .teams:
            return try! NSRegularExpression(pattern: #"https://teams.microsoft.com/l/meetup-join/[a-zA-Z0-9_%\/=\-\+\.?]+"#)
        case .webex:
            return try! NSRegularExpression(pattern: #"https://([a-z0-9.]+)?webex.com.*"#)
        }
    }
    
    public var newCallURL: URL? {
        switch self {
        case .zoom:
            return URL(string: "https://zoom.us/start?confno=123456789&zc=0")!
        case .meet:
            return URL(string: "https://meet.google.com/new")!
        case .teams:
            return URL(string: "https://teams.microsoft.com/l/meeting/new?subject=")!
        case .hangouts:
            return URL(string: "https://hangouts.google.com/call")!
        case .webex:
            return nil
        }
    }
    
}

// MARK: - EventsToMatch (Preference Structure)

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
