//
//  AppDelegate.swift
//  text-popover-macOS
//
//  Created by Li-Wei Yap on 13.07.20.
//  Copyright © 2020 Li-Wei Yap. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    let statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    private let databaseManager = DatabaseManager()
    private let countdownTimerWrapper = CountdownTimerWrapper()
    private let additionalToggableTextOptions = AdditionalToggableTextOptions()
    private let timeoutActivityOptions = TimeoutActivityOptions()
    private let backgroundOptions = BackgroundOptions()
    private let intervalMenuButtonNames = IntervalMenuButtonNames()
    
    static var selfInstance: AppDelegate?
    
    override init()
    {
        super.init()
        AppDelegate.selfInstance = self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        /*
         * Allows keyDown events to be detected
         * https://stackoverflow.com/questions/49716420/adding-a-global-monitor-with-nseventmaskkeydown-mask-does-not-trigger
         */
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled
        {
            print("Access not enabled. Check System Preferences > Security & Privacy.")
        }
        
        let contentView = ContentView()
            .environmentObject(databaseManager)
            .environmentObject(countdownTimerWrapper)
            .environmentObject(additionalToggableTextOptions)
            .environmentObject(timeoutActivityOptions)
            .environmentObject(backgroundOptions)
            .environmentObject(intervalMenuButtonNames)
        
        popover.contentSize = NSSize(width: 425, height: 225)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        /*
         * cannot resize NSImage using resized() from Extensions.swift,
         * because the whole graphics state of the image is saved
         */
        statusItem.button?.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        
        eventMonitor = EventMonitor(mask:
            [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown,
             NSEvent.EventTypeMask.otherMouseDown, NSEvent.EventTypeMask.keyDown,
             NSEvent.EventTypeMask.swipe])
        {
            [weak self] event in
            
            if let popover = self?.popover
            {
                if popover.isShown
                {
                    popover.performClose(event)
                    self?.eventMonitor?.stop()
                }
            }
        }
        eventMonitor?.start()
        
        DistributedNotificationCenter.default.addObserver(self,
                                                          selector: #selector(systemInterfaceModeChanged(sender:)),
                                                          name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
                                                          object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }

    @objc private func togglePopover(_ sender: AnyObject?)
    {
        if popover.isShown
        {
            popover.performClose(sender)
            eventMonitor?.stop()
        }
        else
        {
            if let button = statusItem.button
            {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                eventMonitor?.start()
            }
        }
    }
    
    @objc private func systemInterfaceModeChanged(sender: NSNotification)
    {
        backgroundOptions.darkMode = !backgroundOptions.darkMode
    }
}
