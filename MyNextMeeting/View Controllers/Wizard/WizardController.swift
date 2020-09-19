//
//  WizardController.swift
//  NextCall
//
//  Created by daniele on 31/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa
import Defaults

public class WizardController: NSWindowController {
    
    private enum Step {
        case requestAuth
        case configureApp
    }
    
    @IBOutlet public var holderView: NSView?
    @IBOutlet public var buttonNext: NSButton?
    @IBOutlet public var buttonQuit: NSButton?
    
    @IBOutlet public var viewStep1: NSView?
    @IBOutlet public var viewStep2: NSView?
    
    @IBOutlet public var enableCalendarButton: NSButton!
    @IBOutlet public var enableNotificationsButton: NSButton!
    @IBOutlet public var notifyEvent: NSPopUpButton!
    @IBOutlet public var menuBarStyle: NSPopUpButton!

    @IBOutlet public var calendarsTable: CalendarTableView!
    
    private var currentStep: Step = .requestAuth
    
    public convenience init() {
        self.init(windowNibName: "Wizard")
        self.loadWindow()
        
    }
    
    public func show() {
        loadStep((allAuthsAreSet() ? .configureApp : .requestAuth))
        self.showWindow(nil)
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.center()
    }
    
    @IBAction public func enableCalendarAuth(_ sender: Any?) {
        CalendarManager.shared.requestAuthorization { [weak self] error in
            guard let self = self else { return }
            guard let error = error else {
                self.reloadDataForStep(self.currentStep)
                return
            }
            
            debugPrint(error.localizedDescription)
        }
    }
    
    @IBAction public func enableNotificationsAuth(_ sender: Any?) {
        NotificationManager.shared.requestNotificationAuthorization { [weak self] _ in
            guard let self = self else { return }
            self.reloadDataForStep(self.currentStep)
        }
    }
    
    @IBAction public func quit(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction public func didChangeNotificationMode(_ sender: Any?) {
        Defaults[.notifyEvent] = NotifyOnCall(rawValue: notifyEvent!.selectedItem!.tag)!
    }
    
    @IBAction public func didChangeMenuBarStyle(_ sender: Any?) {
        Defaults[.menuBarStyle] = MenuBarStyle(rawValue: menuBarStyle!.selectedItem!.tag)!
    }
    
    @IBAction public func nextStep(_ sender: Any?) {
        switch self.currentStep {
        case .configureApp:
            StatusBarManager.shared.update()
            Defaults[.wizardCompleted] = true
            self.window?.orderOut(nil)
            
        case .requestAuth:
            loadStep(.configureApp)
        }
    }
    
    private func loadStep(_ step: Step) {
        holderView?.subviews.first?.removeFromSuperview()
        holderView?.addSubview(viewForStep(step))
        currentStep = step
        reloadDataForStep(step)
    }
    
    private func viewForStep(_ step: Step) -> NSView {
        switch step {
        case .requestAuth:
            return viewStep1!
        case .configureApp:
            reloadConfigurationStep()
            return viewStep2!
        }
    }
    
    private func reloadConfigurationStep() {
        calendarsTable.reloadData()

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
    
    private func reloadDataForStep(_ step: Step) {
        switch step {
        case .requestAuth:
            enableCalendarButton?.isEnabled = (CalendarManager.shared.isAuthorized == false)
            NotificationManager.shared.isAuthorized { [weak self] isAuthorized in
                self?.enableNotificationsButton?.isEnabled = (isAuthorized == false)
                self?.reloadNavigationButtons()
            }
            reloadNavigationButtons()
            
            break
        case .configureApp:
            break
        }
    }
    
    private func reloadNavigationButtons() {
        switch currentStep {
        case .requestAuth:
            buttonNext?.isEnabled = allAuthsAreSet()
        case .configureApp:
            buttonNext?.isEnabled = false
        }
    }
    
    private func allAuthsAreSet() -> Bool {
        return (CalendarManager.shared.isAuthorized && NotificationManager.shared.isAuthorized)
    }
    
}
