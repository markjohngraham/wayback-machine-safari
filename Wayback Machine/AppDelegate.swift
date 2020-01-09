//
//  AppDelegate.swift
//  Wayback Machine
//
//  Created by mac-admin on 9/29/18.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func openSupportWebsite(_ sender: Any) {
        NSLog("*** openSupportWebsite()")  // DEBUG
        NSWorkspace.shared.open(URL(string: SupportURL)!)
    }

}

