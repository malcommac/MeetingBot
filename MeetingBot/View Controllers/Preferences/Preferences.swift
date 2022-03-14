//
//  Preferences.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import Foundation
import Preferences
import Defaults
import EventKit

extension Preferences.PaneIdentifier {
    static let calendars = Self("calendars")
    static let general = Self("general")
    static let speedDial = Self("speedDial")
}
