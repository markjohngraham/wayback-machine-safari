//
//  SafariExtensionViewController.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import Foundation
import Cocoa

class WMEMainVC: WMEBaseVC {

    static let shared: WMEMainVC = {
        return WMEMainVC()
    }()

    @IBOutlet weak var txtSearch: NSSearchField!
    @IBOutlet weak var btnSavePage: NSButton!
    @IBOutlet weak var btnSiteMap: NSButton!
    @IBOutlet weak var btnLoginout: NSButton!
    @IBOutlet weak var boxWayback: NSBox!

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        txtSearch.delegate = self
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        loadSearchField()

        // login UI
        let userData = WMEGlobal.shared.getUserData()
        let email = userData?["email"] as? String
        updateLoginUI(WMEGlobal.shared.isLoggedIn(), username: email)
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Helper Functions

    func updateLoginUI(_ isLoggedIn: Bool, username: String? = nil) {
        if isLoggedIn {
            let uname = username ?? "logged in"
            boxWayback?.title = "Wayback (\(uname))"
            btnSavePage?.isEnabled = true
            btnSavePage?.title = "Save Page Now"
            btnLoginout?.title = "Logout"
        } else {
            boxWayback?.title = "Wayback (logged out)"
            btnSavePage?.isEnabled = false
            btnSavePage?.title = "Login to Save Page"
            btnLoginout?.title = "Login"
        }
    }

    func enableSavePageUI(_ enable:Bool) {
        if enable {
            btnSavePage?.title = "Save Page Now"
            btnSavePage?.isEnabled = true
        } else {
            btnSavePage?.title = "Saving..."
            btnSavePage?.isEnabled = false
        }
    }

    func enableSiteMapUI(_ enable:Bool) {
        if enable {
            btnSiteMap?.title = "Site Map"
            btnSiteMap?.isEnabled = true
        } else {
            btnSiteMap?.title = "Loading..."
            btnSiteMap?.isEnabled = false
        }
    }

    func loadSearchField() {
        let userData = WMEGlobal.shared.getUserData()
        if let txt = userData?["searchField"] as? String {
            txtSearch.stringValue = txt
        }
    }

    func saveSearchField(text: String?) {
        if var userData = WMEGlobal.shared.getUserData() {
            userData["searchField"] = text
            WMEGlobal.shared.saveUserData(userData: userData)
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

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Actions

    @IBAction func savePageNowClicked(_ sender: Any) {
        getURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab.")
                return
            }
            guard let userData = WMEGlobal.shared.getUserData(),
                let accessKey = userData["s3accesskey"] as? String,
                let secretKey = userData["s3secretkey"] as? String else
            {
                WMEUtil.shared.showMessage(msg: "Not Logged In?", info: "Try logging out and back in again.")
                return
            }

            self.enableSavePageUI(false)
            WMSAPIManager.shared.capturePage(url: url, accessKey: accessKey, secretKey: secretKey, options:[.allErrors]) {
                (jobId) in

                if let jobId = jobId {
                    WMSAPIManager.shared.getPageStatus(jobId: jobId, accessKey: accessKey, secretKey: secretKey) {
                        (archiveURL, errMsg) in

                        self.enableSavePageUI(true)
                        if let archiveURL = archiveURL {
                            WMEUtil.shared.openTabWithURL(url: archiveURL)
                        } else {
                            WMEUtil.shared.showMessage(msg: "Save Page Failed", info: (errMsg ?? "Unknown Error"))
                        }
                    }
                } else {
                    self.enableSavePageUI(true)
                    WMEUtil.shared.showMessage(msg: "Save Page Failed", info: "Please check that you're online.")
                }
            }
        }
    }

    // TODO: redo waybackPath arg?
    func openInWayback(url: String?, waybackPath: String) {

        guard let url = url else {
            WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab.")
            return
        }
        WMSAPIManager.shared.checkAvailability(url: url) { (waybackURL, originalURL) in
            guard waybackURL != nil else {
                WMEUtil.shared.showMessage(msg: "Not in Internet Archive", info: "The URL is not in Internet Archive. We would suggest to archive the URL by clicking Save Page Now")
                return
            }
            let fullURL = WMSAPIManager.WM_BASE_URL + waybackPath + originalURL
            WMEUtil.shared.openTabWithURL(url: fullURL)
        }
    }

    @IBAction func oldestClicked(_ sender: Any) {
        getURL { (url) in
            self.openInWayback(url: url, waybackPath: WMSAPIManager.WM_OLDEST)
        }
    }

    @IBAction func overviewClicked(_ sender: Any) {
        getURL { (url) in
            self.openInWayback(url: url, waybackPath: WMSAPIManager.WM_OVERVIEW)
        }
    }

    @IBAction func newestClicked(_ sender: Any) {
        getURL { (url) in
            self.openInWayback(url: url, waybackPath: WMSAPIManager.WM_NEWEST)
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

            // remove "http(s)://" from url
            // TODO: refactor?
            if url.contains("http://") {
                url = String(url[url.index(url.startIndex, offsetBy: 7)..<url.endIndex])
            } else if url.contains("https://") {
                url = String(url[url.index(url.startIndex, offsetBy: 8)..<url.endIndex])
            }
            // remove trailing slash
            let lastCharacter = String(url[url.index(before: url.endIndex)])
            if lastCharacter == "/" {
                url = String(url[..<url.index(url.startIndex, offsetBy: url.count - 1)])
            }
            
            WMEUtil.shared.openTabWithURL(url: "https://twitter.com/search?q=\(url)")
        }
    }
    
    @IBAction func siteMapClicked(_ sender: Any) {
        getURL { (url) in
            guard var url = url else {
                WMEUtil.shared.showMessage(msg: "Please type a URL", info: "You need to type a URL in search field or open a URL in a new tab")
                return
            }

            // preparing url
            // TODO: refactor?
            url = url.replacingOccurrences(of: "https://", with: "")
            url = url.replacingOccurrences(of: "http://", with: "")
            if url.contains("/") {
                url = url.components(separatedBy: "/")[0]
            }

            // display loader in webpage
            self.enableSiteMapUI(false)  // FIXME: not updating UI properly
            WMEUtil.shared.dispatchMessage(messageName: "DISPLAY_RT_LOADER", userInfo: ["visible": true])
            WMSAPIManager.shared.getSearchResult(url: url) { (data) in
                if let data = data {
                    // FIXME: need to fix JS code to prevent slow / freezing UI
                    WMEUtil.shared.dispatchMessage(messageName: "RADIAL_TREE", userInfo: ["url": url, "data": data])
                    self.enableSiteMapUI(true)
                } else {
                    self.enableSiteMapUI(true)
                    WMEUtil.shared.showMessage(msg: "Site Map Failed", info: "Loading the Site Map failed.")
                }
            }
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

    @IBAction func loginoutClicked(_ sender: Any) {

        if WMEGlobal.shared.isLoggedIn() {
            // logout clicked, so clear any stored data
            updateLoginUI(false)
            if let userData = WMSAPIManager.shared.logout(userData: WMEGlobal.shared.getUserData()) {
                WMEGlobal.shared.saveUserData(userData: userData)
            }
        } else {
            // login clicked, so go to login view
            self.view.window?.contentViewController = WMELoginVC()
        }
    }

}

///////////////////////////////////////////////////////////////////////////////////
// MARK: - NSSearchFieldDelegate

extension WMEMainVC: NSSearchFieldDelegate {

    func controlTextDidEndEditing(_ obj: Notification) {
        saveSearchField(text: txtSearch.stringValue)
    }

}
