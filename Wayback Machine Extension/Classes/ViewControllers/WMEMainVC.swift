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
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/save/\(url)")
        }
    }
    
    @IBAction func recentVersionClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                guard waybackURL != nil else { return }
                WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/web/2/\(url)")
            })
        }
    }
    
    @IBAction func firstVersionClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                guard waybackURL != nil else { return }
                WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/web/0/\(url)")
            })
        }
    }
    
    @IBAction func overviewClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                guard waybackURL != nil else { return }
                WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/web/*/\(url)")
            })
        }
    }
    
    @IBAction func alexaClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.openTabWithURL(url: "https://www.alexa.com/siteinfo/\(url)")
        }
    }
    
    @IBAction func whoisClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.openTabWithURL(url: "https://www.whois.com/whois/\(url)")
        }
    }
    
    @IBAction func tweetsClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard var url = url else { return }

            if url.contains("http://") {
                url = String(url[url.index(url.startIndex, offsetBy: 7)..<url.endIndex])
            } else if url.contains("https://") {
                url = String(url[url.index(url.startIndex, offsetBy: 8)..<url.endIndex])
            }
            
            let lastCharacter = String(url[url.index(before: url.endIndex)])
            if lastCharacter == "/" {
                url = String(url[..<url.index(url.startIndex, offsetBy: url.count - 1)])
            }
            
            WMEUtil.shared.openTabWithURL(url: "https://twitter.com/search?q=\(url)")
        }
    }
    
    @IBAction func sitemapClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.dispatchMessage(messageName: "RADIAL_TREE", userInfo: ["url": url])
        }
    }
    
    
    @IBAction func facebookClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.openTabWithURL(url: "https://www.facebook.com/sharer/sharer.php?u=\(url)")
        }
    }
    
    @IBAction func twitterClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.openTabWithURL(url: "http://twitter.com/share?url=\(url)")
        }
    }
    
    @IBAction func linkedinClicked(_ sender: Any) {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            WMEUtil.shared.openTabWithURL(url: "https://www.linkedin.com/shareArticle?url=\(url)")
        }
    }
    
    @IBAction func aboutClicked(_ sender: Any) {
        let aboutVC = WMEAboutVC.init(nibName: "WMEAboutVC", bundle: nil)
        self.view.window?.contentViewController = aboutVC
    }
    
}
