//
//  GeneralController.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import AppKit
import Preferences
import KeyboardShortcuts
import Defaults

extension KeyboardShortcuts.Name {
    static let createCall = Self("createCall")
    static let joinCall = Self("joinCall")
}

public class GeneralController: NSViewController, PreferencePane {
    public let preferencePaneIdentifier = Preferences.PaneIdentifier.general
    public let preferencePaneTitle = "General"
    public let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

    public override var nibName: NSNib.Name? { "GeneralController" }

    @IBOutlet public var createCallShorcutPlaceholder: NSView?
    @IBOutlet public var joinCallShorcutPlaceholder: NSView?
    @IBOutlet public var browsersList: NSPopUpButton?
    @IBOutlet public var preferChromeWithMeetService: NSButton?
    @IBOutlet public var callServicesList: NSPopUpButton?
    @IBOutlet public var notifyEvent: NSPopUpButton?

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Setup stuff here
        
        let recorderCreate = KeyboardShortcuts.RecorderCocoa(for: .createCall)
        createCallShorcutPlaceholder?.addSubview(recorderCreate)
        
        let recorderJoin = KeyboardShortcuts.RecorderCocoa(for: .joinCall)
        joinCallShorcutPlaceholder?.addSubview(recorderJoin)
        
        reloadData()
        reloadBrowsers()
        reloadCallServices()
    }
    
    @IBAction public func didChangeBrowser(_ sender: Any?) {
        didChangeDefaultBrowser()
    }
    
    @IBAction public func didChangePreferChromeWithMeet(_ sender: Any?) {
        Defaults[.preferChromeWithMeet] = (preferChromeWithMeetService!.state == .on)
    }
    
    @IBAction public func didChangeNotificationMode(_ sender: Any?) {
        Defaults[.notifyEvent] = NotifyOnCall(rawValue: notifyEvent!.selectedItem!.tag)!
    }
    
    private func reloadData() {
        notifyEvent?.removeAllItems()
        for notifyMode in NotifyOnCall.allCases {
            notifyEvent?.addItem(withTitle: notifyMode.name)
            notifyEvent?.lastItem?.tag = notifyMode.rawValue
        }
        
        notifyEvent?.selectItem(withTag: Defaults[.notifyEvent].rawValue)
    }
    
    private func reloadCallServices() {
        callServicesList?.removeAllItems()
        for service in CallServices.allCases {
            callServicesList?.addItem(withTitle: service.name)
            callServicesList?.lastItem?.tag = service.rawValue
        }
        
        callServicesList?.selectItem(withTag: Defaults[.defaultCallService])
    }
    
    private func reloadBrowsers() {
        preferChromeWithMeetService?.state = (Defaults[.preferChromeWithMeet] ? .on : .off)

        let allBrowsers = PreferenceManager.shared.installedBrowsers()
        
        browsersList?.removeAllItems()
        for (idx, browser) in allBrowsers.enumerated() {
            browsersList?.addItem(withTitle: browser.name)
            browsersList?.lastItem?.image = browser.icon
            browsersList?.lastItem?.tag = idx
        }
        
        guard let userBrowserURL = Defaults[.defaultBrowserURL] else {
            let defaultIndex = allBrowsers.firstIndex(where: { $0.isSystemDefault })
            browsersList?.selectItem(at: defaultIndex ?? 0)
            return
        }
        
        let indexOfSelectedBrowser = allBrowsers.firstIndex(where: { $0.URL == userBrowserURL })
        browsersList?.selectItem(at: indexOfSelectedBrowser ?? 0)
    }
    
    private func didChangeDefaultBrowser() {
        let selectedBrowserIdx = browsersList!.selectedTag()
        let browser = PreferenceManager.shared.installedBrowsers()[selectedBrowserIdx]

        guard browser.isSystemDefault == false else {
            Defaults[.defaultBrowserURL] = nil
            return
        }
        
        Defaults[.defaultBrowserURL] = browser.URL
    }
    
}
