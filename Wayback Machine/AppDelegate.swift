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

    /// Called from the install app's help menu.
    @IBAction func openSupportWebsite(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: SupportURL)!)
    }

}

