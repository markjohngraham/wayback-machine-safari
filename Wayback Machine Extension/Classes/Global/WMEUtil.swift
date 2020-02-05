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
        DispatchQueue.main.async {
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
    
    func openTabWithURL(url: String?) {
        guard let url = url else { return }
        SFSafariApplication.getActiveWindow { (activeWindow) in
            activeWindow?.openTab(with: URL(string: url)!, makeActiveIfPossible: true, completionHandler: { (tab) in
                
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
