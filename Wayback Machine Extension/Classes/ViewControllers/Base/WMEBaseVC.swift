//
//  WMEBaseVC.swift
//  Wayback Machine Extension
//
//  Created by Admin on 10/1/18.
//

import Cocoa
import SafariServices

class WMEBaseVC: SFSafariExtensionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
    }
    
}
