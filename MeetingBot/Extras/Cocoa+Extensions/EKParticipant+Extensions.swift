//
//  EKParticipant+Extensions.swift
//  MeetingBot
//
//  Created by daniele on 21/09/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Foundation
import AppKit
import EventKit

public extension EKParticipant {
    
    var formattedName: NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]

        var fullName = name ?? "Attendee_NoName".l10n

        if isCurrentUser {
            fullName = "Attendee_You".l10n([fullName])
        }

        var roleMark: String
        switch participantRole {
        case .optional:
            roleMark = "*"
        default:
            roleMark = ""
        }

        var status: String
        switch participantStatus {
        case .declined:
            status = ""
            attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.thick.rawValue
        case .tentative:
            status = "Attendee_Status_Tentative".l10n
        case .pending:
            status = "Attendee_Status_NoResponded".l10n
        default:
            status = ""
        }

        let title = "Attendee_Format".l10n([fullName, roleMark, status])
        return NSAttributedString(string: title, attributes: attributes)
    }
    
}
