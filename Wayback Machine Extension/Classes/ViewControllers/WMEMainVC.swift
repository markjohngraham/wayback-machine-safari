//
//  SafariExtensionViewController.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import SafariServices

class WMEMainVC: SFSafariExtensionViewController {
    
    static let shared: WMEMainVC = {
        let shared = WMEMainVC()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
