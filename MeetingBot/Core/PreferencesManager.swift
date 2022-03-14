//
//  PreferencesManager.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Defaults
import EventKit
import AppKit
import LaunchAtLogin

// MARK: - Preferences Keys

public struct SpeedDialItem: Codable {
    var title: String
    var link: String?
    
    public var url: URL? {
        guard let urlString = link,
              let url = URL(string: urlString) else {
            return nil
        }
        
        return url
    }
}

public struct App {
    static let bundleIdentifier: String = "com.danielemargutti.meetingbot"
}

extension Defaults.Keys {
    static let calendarIDs = Key<[String]>("calendarIDs", default: [])
    static let matchEvents = Key<EventsToMatch>("matchEvents", default: .today)
    static let defaultBrowserURL = Key<URL?>("defaultBrowserURL")
    static let preferChromeWithMeet = Key<Bool>("preferChromeWithMeet", default: true)
    static let notifyEvent = Key<NotifyOnCall>("notifyEvent", default: .atTimeOfEvent)
    static let menuBarStyle = Key<MenuBarStyle>("menuBarStyle", default: .icon)
    static let wizardCompleted = Key<Bool>("wizardCompleted", default: false)
    static let speedDialItems = Key<[SpeedDialItem]>("speedDialItems", default: [SpeedDialItem]())
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
    
    public func speedDialItems() -> [SpeedDialItem] {
        return Defaults[.speedDialItems]
    }
    
    public func setSpeedDialItems(_ items: [SpeedDialItem]) {
        Defaults[.speedDialItems] = items
    }
   
}

// MARK: - MenuBarStyle (Preference Structure)

public enum MenuBarStyle: Int, Codable, CaseIterable {
    case icon
    case iconAndCountdown
    case fullTitle
    case shortTitle
    
    public var title: String {
        switch self {
        case .icon:
            return "MenuBarStyle_Icon".l10n
        case .iconAndCountdown:
            return "MenuBarStyle_IconAndCountdown".l10n
        case .fullTitle:
            return "MenuBarStyle_NextTitle".l10n
        case .shortTitle:
            return "MenuBarStyle_NextTitleAbbreviated".l10n
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
        case .never: return "Preferences_Notify_Never".l10n
        case .asApproaching: return "Preferences_Notify_5mBefore".l10n
        case .atTimeOfEvent: return "Preferences_Notify_AtEvent".l10n
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
    case jitsi
    case chime
    case ringcentral
    case gotometting
    case gotowebinar
    case bluejeans
    case eight_x_height
    case demio
    case join_me
    case whereby
    case uberconference
    case blizz
    case vsee
    case starleaf
    case duo
    case voov
    case skype
    case skype4biz
    case skype4bix_hosted
    
    public var name: String? {
        switch self {
        case .zoom:         return "Zoom"
        case .meet:         return "Google Meet"
        case .teams:        return "Microsoft Teams"
        case .hangouts:     return "Hangout"
        case .webex:        return "Webex"
        default:            return nil
        }
    }
    
    public var icon: NSImage? {
        switch self {
        case .zoom: return NSImage(named: "statusbar_zoom")
        case .meet: return NSImage(named: "statusbar_meet")
        case .hangouts: return NSImage(named: "statusbar_hangout")
        case .webex: return NSImage(named: "statusbar_webex")
        case .teams: return NSImage(named: "statusbar_teams")
        case .skype, .skype4biz, .skype4bix_hosted: return NSImage(named: "statusbar_skype")
        default: return nil
        }
    }
    
    public var regularExpression: NSRegularExpression? {
        var regularExpression: String?
        
        switch self {
        case .meet:             regularExpression = #"https://meet.google.com/[a-z-]+"#
        case .hangouts:         regularExpression = #"https://hangouts.google.com.*"#
        case .zoom:             regularExpression = #"https://([a-z0-9.]+)?zoom.us/j/[a-zA-Z0-9?&=]+"#
        case .teams:            regularExpression = #"https://teams.microsoft.com/l/meetup-join/[a-zA-Z0-9_%\/=\-\+\.?]+"#
        case .webex:            regularExpression = #"https://([a-z0-9.]+)?webex.com.*"#
        case .jitsi:            regularExpression = #"https://meet.jit.si/[^\s]*"#
        case .chime:            regularExpression = #"https://([a-z0-9-.]+)?chime.aws/[^\s]*"#
        case .ringcentral:      regularExpression = #"https://meetings.ringcentral.com/[^\s]*"#
        case .gotometting:      regularExpression = #"https://([a-z0-9.]+)?gotomeeting.com/[^\s]*"#
        case .gotowebinar:      regularExpression = #"https://([a-z0-9.]+)?gotowebinar.com/[^\s]*"#
        case .bluejeans:        regularExpression = #"https://([a-z0-9.]+)?bluejeans.com/[^\s]*"#
        case .eight_x_height:   regularExpression = #"https://8x8.vc/[^\s]*"#
        case .demio:            regularExpression = #"https://event.demio.com/[^\s]*"#
        case .join_me:          regularExpression = #"https://join.me/[^\s]*"#
        case .whereby:          regularExpression = #"https://whereby.com/[^\s]*"#
        case .uberconference:   regularExpression = #"https://uberconference.com/[^\s]*"#
        case .blizz:            regularExpression = #"https://go.blizz.com/[^\s]*"#
        case .vsee:             regularExpression = #"https://vsee.com/[^\s]*"#
        case .starleaf:         regularExpression = #"https://meet.starleaf.com/[^\s]*"#
        case .duo:              regularExpression = #"https://duo.app.goo.gl/[^\s]*"#
        case .voov:             regularExpression = #"https://voovmeeting.com/[^\s]*"#
        case .skype:            regularExpression = #"https://join.skype.com/[^\s]*"#
        case .skype4biz:        regularExpression = #"https://meet.lync.com/[^\s]*"#
        case .skype4bix_hosted: regularExpression = #"https://meet\.[^\s]*"#
        }
        
        guard let pattern = regularExpression else {
            return nil
        }
        
        return try! NSRegularExpression(pattern: pattern)
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
        default:
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
