//
//  WMEAboutVC.swift
//  Wayback Machine Extension
//
//  Created by admin on 6/11/19.
//

import Cocoa

class WMEAboutVC: WMEBaseVC {

    @IBOutlet weak var txtVersion: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        txtVersion.stringValue = "\(VERSION) (\(BUILD))"
    }
    
    @IBAction func backClicked(_ sender: Any) {
        if WMEGlobal.shared.isLoggedIn() {
            // return to Main if logged in
            self.view.window?.contentViewController = WMEMainVC.init(nibName: "WMEMainVC", bundle: nil)
        } else {
            // return to Login if logged out
            self.view.window?.contentViewController = WMEMainVC.init(nibName: "WMELoginVC", bundle: nil)
        }
    }

    /// Opens the help.archive.org webpage.
    @IBAction func helpClicked(_ sender: Any) {
        WMEUtil.shared.openTabWithURL(url: "https://help.archive.org")
    }
}
