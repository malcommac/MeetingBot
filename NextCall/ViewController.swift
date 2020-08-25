//
//  ViewController.swift
//  NextCall
//
//  Created by daniele on 24/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        CalendarManager.shared.requestAuthorizationIfNeeded()

        let c = PreferenceManager.shared.favouriteCalendars()
        
        print(c)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

