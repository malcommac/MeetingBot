//
//  SpeedDial.swift
//  MeetingBot
//
//  Created by daniele margutti on 24/10/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import AppKit
import Preferences
import Defaults
import LaunchAtLogin

public class SpeedDialController: NSViewController, PreferencePane {
    public let preferencePaneIdentifier = Preferences.PaneIdentifier.speedDial
    public let preferencePaneTitle = "SpeedDial"
    public let toolbarItemIcon = NSImage(named: "keypad")!

    public override var nibName: NSNib.Name? { "SpeedDialController" }
    
    private var speedDialItems = [SpeedDialItem]()

    @IBOutlet public var tableView: NSTableView!
    @IBOutlet public var buttonRemove: NSButton!
    @IBOutlet public var buttonAdd: NSButton!
    @IBOutlet public var titleLabel: NSTextField!
    @IBOutlet public var subtitleLabel: NSTextField!
    
    @IBAction public func addNewShortcut(_ sender: Any?) {
        speedDialItems.append(SpeedDialItem(title: "New Shortcut", link: nil))
        saveChanges()
        reloadData()
        tableView.editColumn(0, row: speedDialItems.count - 1, with: nil, select: true)
    }
    
    @IBAction public func removeSelectedShortcut(_ sender: Any?) {
        guard tableView.selectedRow != -1 else {
            return
        }
        
        speedDialItems.remove(at: tableView.selectedRow)
        saveChanges()
        reloadData()
    }
    
    public func reloadData() {
        speedDialItems = PreferenceManager.shared.speedDialItems()
        tableView.reloadData()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        titleLabel.stringValue = "SpeedDial_Title".l10n
        subtitleLabel.stringValue = "SpeedDial_Subtitle".l10n
        buttonAdd.title = "Button_Add".l10n
        buttonRemove.title = "Button_Remove".l10n

        reloadData()
    }
    
    private func saveChanges() {
        PreferenceManager.shared.setSpeedDialItems(speedDialItems)
        StatusBarManager.shared.update()
    }
    
}

extension SpeedDialController: NSTableViewDelegate, NSTableViewDataSource {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        speedDialItems.count
    }
    
    public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        switch tableColumn?.identifier.rawValue {
        case "Name":
            speedDialItems[row].title = object as? String ?? ""
        case "Link":
            speedDialItems[row].link = object as? String ?? ""
        default:
            break
        }
        
        saveChanges()
    }
    
    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableColumn?.identifier.rawValue {
        case "Name":
           return speedDialItems[row].title
        case "Link":
            return speedDialItems[row].link
        default:
            return ""
        }
    }
    
    public func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        false
    }
    
}
