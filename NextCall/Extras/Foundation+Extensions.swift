//
//  Foundation+Extensions.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import Defaults

extension NSImage {
    
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        
        return nil
    }
    
}

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

extension TimeInterval {
    func format(using units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: self) ?? ""
    }
}

extension NSMenuItem {
    
    public static func new(title: String, action: Selector?, keyEquivalent: String = "", target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        return item
    }
    
}

extension NSMenu {
    
    @discardableResult
    public func addItem(title: String, action: Selector?, keyEquivalent: String = "", target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem.new(title: title, action: action, keyEquivalent: keyEquivalent, target: target)
        self.addItem(item)
        return item
    }
    
}

extension String {
    
    func regExMatch(regex: NSRegularExpression) -> String? {
        let resultsIterator = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        let resultsMap = resultsIterator.map { String(self[Range($0.range, in: self)!]) }
        if !resultsMap.isEmpty {
            let meetLink = resultsMap[0]
            return meetLink
        }
        return nil
    }
    
    func cleanedNotes() -> String {
        let zoomSeparator = "\n──────────"
        let meetSeparator = "-::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~::~:~::-"
        let cleanNotes = self.components(separatedBy: zoomSeparator)[0].components(separatedBy: meetSeparator)[0]
        return cleanNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func trunc(length: Int, trailing: String = "…") -> String {
           return (self.count > length) ? self.prefix(length) + trailing : self
       }
    
}

extension URL {
    
    private func queryStringParam(_ param: String) -> String? {
        if let urlComponents = NSURLComponents(string: self.absoluteString),
            let queryItems = urlComponents.queryItems {
            return queryItems.filter({ (item) in item.name == param }).first?.value!
        }
        return nil
    }
    
    private func asZoomSchemeURL() -> URL {
        guard self.pathComponents[self.pathComponents.count - 2] == "j" else {
            return self
        }
        
        let confID = self.lastPathComponent
        
        
        var appURLString = "zoommtg://zoom.us/start?confno=\(confID)"
        if let pwd = self.queryStringParam("pwd") {
            appURLString += "&pwd=\(pwd)"
        }
        
        return URL(string: appURLString) ?? self
    }
    
    private func asMeetsSchemeURL() -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.scheme = "msteams"
        return components?.url ?? self
    }
    
    func asSchemeURLForService(_ service: CallServices) -> URL? {
        switch service {
        case .zoom:
            return asZoomSchemeURL()
        case .teams:
            return asMeetsSchemeURL()
        default:
            return self
        }
    }
    
}

extension NSWorkspace {
    
    static func openURL(_ URL: URL?, withBrowser appURL: URL?) {
        guard let URL = URL else {
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        
        guard let targetBrowserURL = appURL ?? PreferenceManager.shared.systemBrowser?.URL else {
            return
        }
        
        NSWorkspace.shared.open([URL],
                                withApplicationAt: targetBrowserURL,
                                configuration: configuration, completionHandler: { app, error in
                                    if error != nil {
                                        NSWorkspace.shared.open(URL)
                                    }
        })
    }
    
    static func openURL(_ URL: URL?) {
        guard let URL = URL else { return }
        let isHTTPURL = ["http", "https"].contains(URL.scheme ?? "")
        
        guard isHTTPURL == false else {
            openURL(URL, withBrowser: Defaults[.defaultBrowserURL])
            return
        }
        
        if NSWorkspace.shared.open(URL) == false {
            openURL(URL, withBrowser: Defaults[.defaultBrowserURL])
        }
    }
    
    static func openLink(_ link: URL) -> Bool {
        let result = NSWorkspace.shared.open(link)
        if result {
            NSLog("Open \(link) in default browser")
        } else {
            NSLog("Can't open \(link) in default browser")
        }
        return result
    }

    
}
