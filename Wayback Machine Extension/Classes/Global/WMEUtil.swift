//
//  WMEUtil.swift
//  Wayback Machine Extension
//
//  Created by admin on 6/10/19.
//

import Foundation
import SafariServices

class WMEUtil: NSObject {
    
    static let shared: WMEUtil = {
        let shared = WMEUtil()
        return shared
    }()
    
    func showMessage(msg: String, info: String) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let alert = NSAlert()
            alert.messageText = msg
            alert.informativeText = info
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func dispatchMessage(messageName: String, userInfo: [String: Any]) {
        SFSafariApplication.getActiveWindow(completionHandler: {(activeWindow) in
            activeWindow?.getActiveTab(completionHandler: {(activeTab) in
                guard let activeTab = activeTab else { return }
                
                activeTab.getActivePage(completionHandler: {(activePage) in
                    guard let activePage = activePage else { return }
                    activePage.dispatchMessageToScript(withName: messageName, userInfo: userInfo)
                })
            })
        })
    }
    
    func getActivePageURL(completion: @escaping(String?) -> Void) {
        SFSafariApplication.getActiveWindow { (activeWindow) in
            activeWindow?.getActiveTab(completionHandler: { (activeTab) in
                activeTab?.getActivePage(completionHandler: { (activePage) in
                    activePage?.getPropertiesWithCompletionHandler({ (properties) in
                        completion(properties?.url?.absoluteString)
                    })
                })
            })
        }
    }
    
    func getActivePageTitle(completion: @escaping(String?) -> Void) {
        SFSafariApplication.getActiveWindow { (activeWindow) in
            activeWindow?.getActiveTab(completionHandler: { (activeTab) in
                activeTab?.getActivePage(completionHandler: { (activePage) in
                    activePage?.getPropertiesWithCompletionHandler({ (properties) in
                        completion(properties?.title)
                    })
                })
            })
        }
    }

    func openTabWithURL(url: String?, completion: @escaping() -> Void = { }) {
        if (DEBUG_LOG) { NSLog("*** openTabWithURL() url: \(String(describing: url))") }
        guard let url = url, let realURL = URL(string: url) else { return }

        // FIXME: "Error connecting back to host app: NSCocoaErrorDomain, code: 4099" (see in console)
        // This is preventing the browser from opening the URL after a page is archived.
        // Looks like this is a bug introduced by Apple in Safari 13 that is still not fixed:
        // https://forums.developer.apple.com/thread/121032
        // https://forums.developer.apple.com/thread/118902

        SFSafariApplication.getActiveWindow { (activeWindow) in
            activeWindow?.openTab(with: realURL, makeActiveIfPossible: true, completionHandler: { (tab) in
                if (DEBUG_LOG) { NSLog("*** openTabWithURL() completionHandler:") }
                completion()
            })
        }
    }
    
    func getOriginalURL(url: String) -> String {
        var originalURL = url
        let tempArray = url.components(separatedBy: "http")
        if (tempArray.count > 2) {
            originalURL = "http" + tempArray[2]
        }
        return originalURL
    }

}
