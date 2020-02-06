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
        txtVersion.stringValue = "\(APP_VERSION) (\(APP_BUILD))"
    }
    
    @IBAction func backClicked(_ sender: Any) {
        self.view.window?.contentViewController = WMEMainVC()
    }

    /// Opens the help webpage.
    @IBAction func helpClicked(_ sender: Any) {
        WMEUtil.shared.openTabWithURL(url: "https://archive.org/about/contact.php")
    }
}
