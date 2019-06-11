//
//  SafariExtensionHandler.swift
//  Wayback Machine Extension
//
//  Created by mac-admin on 9/29/18.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
        
        if (messageName == "_onBeforeNavigate") {
            handleBeforeNavigate()
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return WMEMainVC.shared
    }
    
    func handleBeforeNavigate() {
        WMEUtil.shared.getActivePageURL { (url) in
            guard let url = url else { return }
            self.getResponse(url: url, completion: { (status) in
                guard let status = status else { return }
                if (HTTPFailCodes.index(of: status) == nil) {
                    return
                }
                
                WMEUtil.shared.wmAvailabilityCheck(url: url, completion: { (waybackURL, url) in
                    guard let waybackURL = waybackURL else { return }
                    SFSafariApplication.getActiveWindow(completionHandler: {(activeWindow) in
                        activeWindow?.getActiveTab(completionHandler: {(activeTab) in
                            activeTab?.getActivePage(completionHandler: {(activePage) in
                                activePage?.dispatchMessageToScript(withName: "showBanner", userInfo: ["url": waybackURL])
                            })
                        })
                    })
                    
                })
            })
        }
    }
    
    func getResponse(url: String?, completion: @escaping (Int?) -> Void) {
        if (url == nil) {return}
        
        var request = URLRequest(url: URL(string: url!)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let _ = data, error == nil else {
                print("error=\(String(describing: error))")
                completion(nil)
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            
            completion(httpStatus?.statusCode)
        }
        
        task.resume()
    }

}
