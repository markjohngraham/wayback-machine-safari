//
//  SafariExtensionViewController.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import Cocoa

class WMEMainVC: WMEBaseVC {
    
    static let shared: WMEMainVC = {
        let shared = WMEMainVC()
        return shared
    }()
    
    //- MARK: Actions

    @IBAction func savePageNowClicked(_ sender: Any) {
        WMEGlobal.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEGlobal.shared.openTabWithURL(url: Save_URL + url)
        }
    }
    
    @IBAction func recentVersionClicked(_ sender: Any) {
        WMEGlobal.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEGlobal.shared.wmAvailabilityCheck(url: url, timestamp: nil, completion: { (waybackURL, url) in
                guard let waybackURL = waybackURL else { return }
                WMEGlobal.shared.openTabWithURL(url: waybackURL)
            })
        }
    }
    
    @IBAction func firstVersionClicked(_ sender: Any) {
        WMEGlobal.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEGlobal.shared.wmAvailabilityCheck(url: url, timestamp: "00000000000000", completion: { (waybackURL, url) in
                guard let waybackURL = waybackURL else { return }
                WMEGlobal.shared.openTabWithURL(url: waybackURL)
            })
        }
    }
    
    @IBAction func overviewClicked(_ sender: Any) {
    }
    
    @IBAction func alexaClicked(_ sender: Any) {
    }
    
    @IBAction func whoisClicked(_ sender: Any) {
    }
    
    @IBAction func tweetsClicked(_ sender: Any) {
    }
    
    @IBAction func sitemapClicked(_ sender: Any) {
    }
    
    
    @IBAction func facebookClicked(_ sender: Any) {
        WMEGlobal.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            
            WMEGlobal.shared.getActivePageTitle { (title) in
                guard let title = title else { return }
                let sharingURL = "https://www.facebook.com/sharer/sharer.php?u=\(url)&title=\(title)"
                WMEGlobal.shared.openTabWithURL(url: sharingURL)
            }
        }
    }
    
    @IBAction func twitterClicked(_ sender: Any) {
        WMEGlobal.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            let sharingURL = "http://twitter.com/share?url=\(url)&via=internetarchive"
            WMEGlobal.shared.openTabWithURL(url: sharingURL)
        }
    }
    
    @IBAction func linkedinClicked(_ sender: Any) {
    }
    
    @IBAction func aboutClicked(_ sender: Any) {
    }
    
}
