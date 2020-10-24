//
//  GeneralController.swift
//  NextCall
//
//  Created by daniele on 25/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
//

import AppKit
import Preferences
import Defaults
import LaunchAtLogin

public class GeneralController: NSViewController, PreferencePane {
    public let preferencePaneIdentifier = Preferences.PaneIdentifier.general
    public let preferencePaneTitle = "General"
    public let toolbarItemIcon = NSImage(named: "notification")!

    public override var nibName: NSNib.Name? { "GeneralController" }

    @IBOutlet public var browsersListLabel: NSTextField?
    @IBOutlet public var notifyEventLabel: NSTextField?
    @IBOutlet public var notifyEventSublabel: NSTextField?
    @IBOutlet public var menuBarStyleLabel: NSTextField?

    @IBOutlet public var browsersList: NSPopUpButton?
    @IBOutlet public var preferChromeWithMeetService: NSButton?
    @IBOutlet public var notifyEvent: NSPopUpButton?
    @IBOutlet public var menuBarStyle: NSPopUpButton?
    @IBOutlet public var launchAtLogin: NSButton?

    public override func viewDidLoad() {
        super.viewDidLoad()

        browsersListLabel?.stringValue = "Preferences_Default_Browser".l10n
        preferChromeWithMeetService?.stringValue = "Preferences_PreferChrome".l10n
        notifyEventLabel?.stringValue = "Preferences_NotifyEvent".l10n
        notifyEventSublabel?.stringValue = "Preferences_NotifyEvent_Desc".l10n
        menuBarStyleLabel?.stringValue = "Preferences_MenuBar".l10n
        launchAtLogin?.stringValue = "Preferences_LaunchLogin".l10n

        reloadData()
        reloadBrowsers()
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
    
    @IBAction public func didChangeMenuBarStyle(_ sender: Any?) {
        Defaults[.menuBarStyle] = MenuBarStyle(rawValue: menuBarStyle!.selectedItem!.tag)!
        StatusBarManager.shared.update()
    }
    
    @IBAction public func didChangeLaunchAtLogin(_ sender: Any?) {
        LaunchAtLogin.isEnabled = launchAtLogin!.state == .on
    }
    
    private func reloadData() {
        launchAtLogin?.state = (LaunchAtLogin.isEnabled ? .on : .off)
        
        notifyEvent?.removeAllItems()
        for notifyMode in NotifyOnCall.allCases {
            notifyEvent?.addItem(withTitle: notifyMode.name)
            notifyEvent?.lastItem?.tag = notifyMode.rawValue
        }
        
        notifyEvent?.selectItem(withTag: Defaults[.notifyEvent].rawValue)
        
        menuBarStyle?.removeAllItems()
        MenuBarStyle.allCases.forEach { style in
            menuBarStyle?.addItem(withTitle: style.title)
            menuBarStyle?.lastItem?.tag = style.rawValue
        }
        menuBarStyle?.selectItem(withTag: Defaults[.menuBarStyle].rawValue)
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
