//
//  ViewController.swift
//  Wayback Machine
//
//  Created by mac-admin on 9/29/18.
//

import Cocoa
import SafariServices

class WMMainVC: WMBaseVC, NSWindowDelegate {

    @IBOutlet weak var txtVersion: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        txtVersion.stringValue = "\(APP_VERSION) (\(APP_BUILD))"
    }

    override func viewDidAppear() {
        self.view.window?.delegate = self
        self.view.window?.styleMask = [NSWindow.StyleMask.closable, NSWindow.StyleMask.titled, NSWindow.StyleMask.miniaturizable]
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    //- MARK: Actions
    
    @IBAction func showPreferencesClicked(_ sender: Any) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "archive.org.waybackmachine.mac.extension") { (error) in
            if let error = error {
                print("*** Error launching the extension's preferences: %@", error)
            }
        }
    }
}

