//
//  SafariExtensionHandler.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        NSLog("*** messageReceived(): %@", messageName)  // DEBUG
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("*** The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
        
        if (messageName == "_onBeforeNavigate") {
            // NOTE: Commenting this out will prevent keychain alert during auth logins,
            // but will also disable auto-checking the archive when http GET returns an error status code.
            //handleBeforeNavigate()
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("*** The extension's toolbar item was clicked")
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
        NSLog("*** handleBeforeNavigate()")  // DEBUG
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            self.getResponse(url: url) { (status) in
                guard let status = status else { return }
                // if success (200) or not one of the fail codes then return, else check the archive
                // FIXME: Need to handle (401) Unauthorized, but before the login prompt?
                if (HTTPFailCodes.index(of: status) == nil) { return }
                WMSAPIManager.shared.checkAvailability(url: url) { (waybackURL, originalURL) in
                    guard let waybackURL = waybackURL else { return }
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
    
    func getResponse(url: String?, completion: @escaping (Int?) -> Void) {
        NSLog("*** getResponse() url: %@", url ?? "")  // DEBUG
        if (url == nil) {return}
        
        var request = URLRequest(url: URL(string: url!)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let _ = data, error == nil else {
                NSLog("*** error: \(String(describing: error))")
                completion(nil)
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            NSLog("*** statusCode: \(String(describing: httpStatus?.statusCode))")  // DEBUG
            NSLog("*** allHeaderFields: \(String(describing: httpStatus?.allHeaderFields))")  // DEBUG
            completion(httpStatus?.statusCode)
        }
        
        task.resume()
    }

}
