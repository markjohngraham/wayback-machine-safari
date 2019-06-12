//
//  WMEAboutVC.swift
//  Wayback Machine Extension
//
//  Created by admin on 6/11/19.
//

import Cocoa

class WMEAboutVC: WMEBaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func backClicked(_ sender: Any) {
        let mainVC = WMEMainVC.init(nibName: "WMEMainVC", bundle: nil)
        self.view.window?.contentViewController = mainVC
    }
    
}
