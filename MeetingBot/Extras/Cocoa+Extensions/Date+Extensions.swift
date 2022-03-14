//
//  AppKit+NSImage.swift
//  NextCall
//
//  Created by daniele on 30/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa

// MARK: - Date

extension Date {
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    func byAddingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    func toFormat(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    var toLocal: Date {
        let tz = NSTimeZone.local
        let sec = tz.secondsFromGMT(for: self)
        return Date(timeInterval: TimeInterval(sec), since: self)
    }
    
}

// MARK: - TimeInterval

extension TimeInterval {
    
    /// Format time interval.
    /// - Parameter units: units to use.
    /// - Returns: String
    func format(using units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: self) ?? ""
    }
    
}
