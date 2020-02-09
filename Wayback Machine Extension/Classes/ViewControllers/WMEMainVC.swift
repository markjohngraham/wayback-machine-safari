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

        // update login UI & restore button states
        if WMEGlobal.shared.isLoggedIn() {
            let userData = WMEGlobal.shared.getUserData()
            let email = userData?["email"] as? String
            updateLoginUI(true, username: email)
            enableSavePageUI(WMEGlobal.shared.savePageEnabled)
        } else {
            updateLoginUI(false)
        }
        enableSiteMapUI(WMEGlobal.shared.siteMapEnabled)
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
        // save state in case view disappears
        WMEGlobal.shared.savePageEnabled = enable
    }

    func enableSiteMapUI(_ enable:Bool) {
        if enable {
            btnSiteMap?.title = "Site Map"
            btnSiteMap?.isEnabled = true
        } else {
            btnSiteMap?.title = "Loading..."
            btnSiteMap?.isEnabled = false
        }
        // save state in case view disappears
        WMEGlobal.shared.siteMapEnabled = enable
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

    /// Percent encode any whitespace for given URL.
    func encodeWhitespace(_ url: String?) -> String? {
        return url?.addingPercentEncoding(withAllowedCharacters: (CharacterSet.whitespacesAndNewlines).inverted)
    }

    /// Grab URL from search field if it's not empty, otherwise grab from active open browser tab.
    func grabURL(completion: @escaping (String?) -> Void) {
        if !txtSearch.stringValue.isEmpty {
            completion(encodeWhitespace(txtSearch.stringValue))
        } else {
            WMEUtil.shared.getActivePageURL { (url) in
                completion(url)
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Actions

    @IBAction func savePageNowClicked(_ sender: Any) {

        self.enableSavePageUI(false)
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            guard let userData = WMEGlobal.shared.getUserData(),
                let accessKey = userData["s3accesskey"] as? String,
                let secretKey = userData["s3secretkey"] as? String else
            {
                WMEUtil.shared.showMessage(msg: "Not Logged In?", info: "Try logging out and back in again.")
                return
            }

            WMSAPIManager.shared.capturePage(url: url, accessKey: accessKey, secretKey: secretKey, options:[.allErrors]) {
                (jobId) in

                if let jobId = jobId {
                    // short delay before retrieving status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        WMSAPIManager.shared.getPageStatus(jobId: jobId, accessKey: accessKey, secretKey: secretKey) {
                            (archiveURL, errMsg) in

                            self.enableSavePageUI(true)
                            if archiveURL != nil {
                                WMEUtil.shared.showMessage(msg: "Page Saved", info: "The following website has been archived:\n\(url)")
                                //WMEUtil.shared.openTabWithURL(url: archiveURL)
                            } else {
                                WMEUtil.shared.showMessage(msg: "Save Page Failed", info: (errMsg ?? "Unknown Error"))
                            }
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
            WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
            return
        }
        WMSAPIManager.shared.checkAvailability(url: url) { (waybackURL, originalURL) in
            guard waybackURL != nil else {
                WMEUtil.shared.showMessage(msg: "Not in Internet Archive", info: "The URL is not in Internet Archive. We would suggest to archive the URL by clicking Save Page Now.")
                return
            }
            let fullURL = WMSAPIManager.WM_BASE_URL + waybackPath + originalURL
            WMEUtil.shared.openTabWithURL(url: fullURL)
        }
    }

    @IBAction func oldestClicked(_ sender: Any) {
        grabURL { (url) in
            self.openInWayback(url: url, waybackPath: WMSAPIManager.WM_OLDEST)
        }
    }

    @IBAction func overviewClicked(_ sender: Any) {
        grabURL { (url) in
            self.openInWayback(url: url, waybackPath: WMSAPIManager.WM_OVERVIEW)
        }
    }

    @IBAction func newestClicked(_ sender: Any) {
        grabURL { (url) in
            self.openInWayback(url: url, waybackPath: WMSAPIManager.WM_NEWEST)
        }
    }

    @IBAction func alexaClicked(_ sender: Any) {
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            guard let urlHost = URL(string: WMSAPIManager.shared.fullWebURL(url))?.host else {
                WMEUtil.shared.showMessage(msg: "Incorrect URL", info: "Please type a correct URL in the search field or web browser.")
                return
            }
            // search alexa
            WMEUtil.shared.openTabWithURL(url: "https://www.alexa.com/siteinfo/" + urlHost)
        }
    }
    
    @IBAction func whoisClicked(_ sender: Any) {
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            guard let urlHost = URL(string: WMSAPIManager.shared.fullWebURL(url))?.host else {
                WMEUtil.shared.showMessage(msg: "Incorrect URL", info: "Please type a correct URL in the search field or web browser.")
                return
            }
            // search whois
            WMEUtil.shared.openTabWithURL(url: "https://www.whois.com/whois/" + urlHost)
        }
    }
    
    @IBAction func tweetsClicked(_ sender: Any) {
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            let fullURL = WMSAPIManager.shared.fullWebURL(url)
            guard let urlHost = URL(string: fullURL)?.host, let urlPath = URL(string: fullURL)?.path else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            // search twitter
            WMEUtil.shared.openTabWithURL(url: "https://twitter.com/search?q=" + urlHost + urlPath)
        }
    }
    
    @IBAction func siteMapClicked(_ sender: Any) {
        if (DEBUG_LOG) { NSLog("*** siteMapClicked()") }

        self.enableSiteMapUI(false)
        let sUrl = encodeWhitespace(txtSearch.stringValue) ?? ""
        if sUrl.isEmpty {
            // use the current url in web browser
            if (DEBUG_LOG) { NSLog("*** is empty") }
            WMEUtil.shared.getActivePageURL { (url) in
                self.showSiteMap(url: url)
            }
        } else {
            // open the url in web browser before showing the site map
            if (DEBUG_LOG) { NSLog("*** not empty: \(sUrl)") }
            let tUrl = WMSAPIManager.shared.fullWebURL(sUrl)
            if (DEBUG_LOG) { NSLog("*** open url: \(tUrl)") }
            WMEUtil.shared.openTabWithURL(url: tUrl, completion: {
                if (DEBUG_LOG) { NSLog("*** openTabWithURL completed") }
                // clear search field in case user clicks "Site Map" button again
                self.txtSearch.stringValue = ""
                self.saveSearchField(text: "")
                // short delay to allow website to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    WMEUtil.shared.getActivePageURL { (url) in
                        self.showSiteMap(url: url)
                    }
                }
            })
        }
    }

    func showSiteMap(url: String?) {
        if (DEBUG_LOG) { NSLog("*** showSiteMap() url: \(String(describing: url))") }
        guard let url = url else {
            WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
            return
        }
        guard let urlHost = URL(string: WMSAPIManager.shared.fullWebURL(url))?.host else {
            WMEUtil.shared.showMessage(msg: "Incorrect URL", info: "Please type a correct URL in the search field or web browser.")
            return
        }
        // display loader in webpage
        WMEUtil.shared.dispatchMessage(messageName: "DISPLAY_RT_LOADER", userInfo: ["visible": true])
        WMSAPIManager.shared.getSearchResult(url: urlHost) { (data) in
            if let data = data {
                WMEUtil.shared.dispatchMessage(messageName: "RADIAL_TREE", userInfo: ["url": urlHost, "data": data])
                self.enableSiteMapUI(true)
            } else {
                self.enableSiteMapUI(true)
                WMEUtil.shared.showMessage(msg: "Site Map Failed", info: "Loading the Site Map failed.")
            }
        }
    }
    
    @IBAction func facebookClicked(_ sender: Any) {
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            // share on facebook
            WMEUtil.shared.openTabWithURL(url: "https://www.facebook.com/sharer/sharer.php?u=" + url)
        }
    }
    
    @IBAction func twitterClicked(_ sender: Any) {
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            // share on twitter
            WMEUtil.shared.openTabWithURL(url: "http://twitter.com/share?url=" + url)
        }
    }
    
    @IBAction func linkedinClicked(_ sender: Any) {
        grabURL { (url) in
            guard let url = url else {
                WMEUtil.shared.showMessage(msg: "Missing URL", info: "Please type a URL in the search field or open a URL in the web browser.")
                return
            }
            // share on linkedin
            WMEUtil.shared.openTabWithURL(url: "https://www.linkedin.com/shareArticle?url=" + url)
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
