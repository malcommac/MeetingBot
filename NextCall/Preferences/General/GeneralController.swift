//
//  GeneralController.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import AppKit
import Preferences

public class GeneralController: NSViewController, PreferencePane {
    public let preferencePaneIdentifier = Preferences.PaneIdentifier.general
    public let preferencePaneTitle = "General"
    public let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

    public override var nibName: NSNib.Name? { "GeneralController" }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Setup stuff here
    }
    
}
