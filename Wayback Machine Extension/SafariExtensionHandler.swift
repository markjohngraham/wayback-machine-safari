//
//  SafariExtensionHandler.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import Foundation
import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        if (DEBUG_LOG) { NSLog("*** messageReceived(): %@", messageName) }
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            if (DEBUG_LOG) { NSLog("*** The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))") }

            if (messageName == "OPEN_URL") {
                /*
                if let userInfo = userInfo,
                    let wbPath = userInfo["wbPath"] as? String,
                    let pageURL = userInfo["pageURL"] as? String {
                    let archiveURL = WMSAPIManager.WM_BASE_URL + wbPath + pageURL
                    // This isn't currently working, so instead we're opening the URL in script.js
                    // "Error connecting back to host app: NSCocoaErrorDomain, code: 4099"
                    // WMEUtil.shared.openTabWithURL(url: archiveURL)
                }
                */
            }
        }
        
        if (messageName == "_onBeforeNavigate") {
            // NOTE: Commenting this out will prevent keychain alert during auth logins,
            // but will also disable auto-checking the archive when http GET returns an error status code.
            handleBeforeNavigate()
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        if (DEBUG_LOG) { NSLog("*** The extension's toolbar item was clicked") }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        //let vc = WMEGlobal.shared.isLoggedIn() ? WMEMainVC() : WMELoginVC()
        let vc = WMEMainVC()
        return vc
    }
    
    func handleBeforeNavigate() {
        if (DEBUG_LOG) { NSLog("*** handleBeforeNavigate()") }
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            self.getResponse(url: url) { (status) in
                guard let status = status else { return }
                // if success (200) or not one of the fail codes then return, else check the archive
                if (HTTPFailCodes.firstIndex(of: status) == nil) { return }
                WMSAPIManager.shared.checkAvailability(url: url) { (waybackURL, originalURL) in
                    guard let waybackURL = waybackURL else { return }
                    if (DEBUG_LOG) { NSLog("*** in wayback: \(waybackURL)") }
                    SFSafariApplication.getActiveWindow(completionHandler: {(activeWindow) in
                        activeWindow?.getActiveTab(completionHandler: {(activeTab) in
                            activeTab?.getActivePage(completionHandler: {(activePage) in
                                activePage?.dispatchMessageToScript(withName: "SHOW_BANNER", userInfo: ["url": waybackURL])
                            })
                        })
                    })
                }
            }
        }
    }
    
    func getResponse(url: String, completion: @escaping (Int?) -> Void) {
        if (DEBUG_LOG) { NSLog("*** getResponse() url: \(url)") }

        guard let realURL = URL(string: url) else { return }
        var request = URLRequest(url: realURL)
        request.httpMethod = "HEAD"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let _ = data, error == nil else {
                NSLog("*** error: \(String(describing: error))")
                completion(nil)
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            if (DEBUG_LOG) { NSLog("*** statusCode: \(String(describing: httpStatus?.statusCode))") }
            if (DEBUG_LOG) { NSLog("*** allHeaderFields: \(String(describing: httpStatus?.allHeaderFields))") }
            completion(httpStatus?.statusCode)
        }
        task.resume()
    }

}
