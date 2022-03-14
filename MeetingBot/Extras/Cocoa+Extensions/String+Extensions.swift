//
//  Foundation+Extensions.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Cocoa

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
    
    var l10n: String {
        return NSLocalizedString(self, comment: "**\(self)**")
    }
    
    func l10n(_ values: [CVarArg]) -> String {
        return String(format: self.l10n, arguments: values)
    }
    
}
