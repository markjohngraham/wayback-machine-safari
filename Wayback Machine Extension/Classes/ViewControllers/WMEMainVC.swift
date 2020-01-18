//
//  SafariExtensionViewController.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import Cocoa

class WMEMainVC: WMEBaseVC {
    
    static let shared: WMEMainVC = {
        return WMEMainVC()
    }()
    
    //- MARK: Actions
    @IBOutlet weak var txtSearch: NSTextField!
    
    override func viewDidAppear() {
        NSLog("*** WMEMainVC.viewDidAppear()")  // DEBUG

        if let userData = WMEGlobal.shared.getUserData(),
            let isLoggedin = userData["logged-in"] as? Bool,
            let email = userData["email"] as? String,
            let password = userData["password"] as? String,
            isLoggedin == true {
            
            WMEAPIManager.shared.login(email: email, password: password) { (loggedInUser, loggedInSig) in
                
                if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
                    WMEGlobal.shared.saveUserData(userData: [
                        "email": email,
                        "password": password,
                        "logged-in-user": loggedInUser,
                        "logged-in-sig": loggedInSig,
                        "logged-in": true
                    ])
                } else {
                    self.view.window?.contentViewController = WMELoginVC()
                }
            }
        } else {
            self.view.window?.contentViewController = WMELoginVC()
        }
        
    }
    
    func getURL(completion: @escaping (String?) -> Void) {
        if !txtSearch.stringValue.isEmpty {
            completion(txtSearch.stringValue)
        } else {
            WMEUtil.shared.getActivePageURL { (url) in
                completion(url)
            }
        }
    }
    
    @IBAction func savePageNowClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }

            guard let userData = WMEGlobal.shared.getUserData(),
                let loggedInUser = userData["logged-in-user"] as? HTTPCookie,
                let loggedInSig = userData["logged-in-sig"] as? HTTPCookie else {
                
                return
            }
            
            WMEAPIManager.shared.requestCapture(url: url, logged_in_user: loggedInUser, logged_in_sig: loggedInSig, options:[.allErrors], completion: { (jobId) in
                
                if jobId == nil {
                    WMEUtil.shared.showMessage(msg: "Error", info: "Archiving failed")
                    return
                }
                
                WMEAPIManager.shared.requestCaptureStatus(job_id: jobId!, logged_in_user: loggedInUser, logged_in_sig: loggedInSig, completion: { (url, error) in
                    if let url = url {
                        WMEUtil.shared.openTabWithURL(url: url)
                    } else {
                        WMEUtil.shared.showMessage(msg: "Error", info: (error ?? "Unknown"))
                    }
                })
            })
        }
    }
    
    @IBAction func recentVersionClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab.")
                return
            }
            WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                guard waybackURL != nil else {
                    WMEUtil.shared.showMessage(msg: "Not in Internet Archive", info: "The URL is not in Internet Archive. We would suggest to archive the URL by clicking Save Page Now")
                    return
                }
                WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/web/2/\(url)")
            })
        }
    }
    
    @IBAction func firstVersionClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab.")
                return
            }
            WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                guard waybackURL != nil else {
                    WMEUtil.shared.showMessage(msg: "Not in Internet Archive", info: "The URL is not in Internet Archive. We would suggest to archive the URL by clicking Save Page Now")
                    return
                }
                WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/web/0/\(url)")
            })
        }
    }
    
    @IBAction func overviewClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab.")
                return
            }
            WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                guard waybackURL != nil else {
                    WMEUtil.shared.showMessage(msg: "Not in Internet Archive", info: "The URL is not in Internet Archive. We would suggest to archive the URL by clicking Save Page Now")
                    return
                }
                WMEUtil.shared.openTabWithURL(url: "\(BaseURL)/web/*/\(url)")
            })
        }
    }
    
    @IBAction func alexaClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            WMEUtil.shared.openTabWithURL(url: "https://www.alexa.com/siteinfo/\(url)")
        }
    }
    
    @IBAction func whoisClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            WMEUtil.shared.openTabWithURL(url: "https://www.whois.com/whois/\(url)")
        }
    }
    
    @IBAction func tweetsClicked(_ sender: Any) {
        getURL { (url) in
            guard var url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            
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
        getURL { (url) in
            guard var url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            
            url = url.replacingOccurrences(of: "https://", with: "")
            url = url.replacingOccurrences(of: "http://", with: "")
            
            if url.contains("/") {
                url = url.components(separatedBy: "/")[0]
            }
            
            WMEUtil.shared.dispatchMessage(messageName: "DISPLAY_RT_LOADER", userInfo: [
                "visible": true
            ])
            
            WMEAPIManager.shared.getSearchResult(url: url, completion: { (data) in
                WMEUtil.shared.dispatchMessage(messageName: "RADIAL_TREE", userInfo: [
                    "url": url,
                    "data": data
                ])
            })
            
        }
    }
    
    @IBAction func facebookClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            WMEUtil.shared.openTabWithURL(url: "https://www.facebook.com/sharer/sharer.php?u=\(url)")
        }
    }
    
    @IBAction func twitterClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            WMEUtil.shared.openTabWithURL(url: "http://twitter.com/share?url=\(url)")
        }
    }
    
    @IBAction func linkedinClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }
            WMEUtil.shared.openTabWithURL(url: "https://www.linkedin.com/shareArticle?url=\(url)")
        }
    }
    
    @IBAction func aboutClicked(_ sender: Any) {
        self.view.window?.contentViewController = WMEAboutVC()
    }

    @IBAction func logoutClicked(_ sender: Any) {
        // clear login data
        WMEGlobal.shared.saveUserData(userData: [
            "email": nil,
            "password": nil,
            "logged-in-user": nil,
            "logged-in-sig": nil,
            "logged-in": false
        ])
        // go to Login view
        self.view.window?.contentViewController = WMELoginVC()
    }

}
