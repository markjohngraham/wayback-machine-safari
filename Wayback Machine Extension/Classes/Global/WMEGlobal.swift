//
//  WMGlobal.swift
//  Wayback Machine Extension
//
//  Created by admin on 6/7/19.
//

import Cocoa
import SafariServices

class WMEGlobal: NSObject {
    
    static let shared: WMEGlobal = {
        let shared = WMEGlobal()
        return shared
    }()
    
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
    
    func wmAvailabilityCheck(url: String, timestamp: String?, completion: @escaping (String?, String) -> Void) {
        
        var postString = "url=" + url
        if timestamp != nil {
            postString += "&&timestamp=" + timestamp!
        }
        
        var request = URLRequest(url: URL(string: Availability_API_URL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        request.setValue("2", forHTTPHeaderField: "Wayback-Api-Version")
        request.setValue("Wayback_Machine_Safari_XC/\(VERSION)", forHTTPHeaderField: "User-Agent")
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                return
            }
            
            do {
                
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]{
                    
                    completion(self.getWaybackUrlFromResponse(response: json), url)
                    
                } else {
                    completion(nil, url)
                }
                
            } catch _ {
                completion(nil, url)
            }
            
        }
        
        task.resume()
    }
    
    func getWaybackUrlFromResponse(response: [String: Any]) -> String? {
        let results = response["results"] as Any?
        let results_first = ((response["results"] as? [Any])?[0])
        let archived_snapshots = (results_first as? [String: Any])?["archived_snapshots"]
        let closest = (archived_snapshots as? [String: Any])?["closest"]
        let available = (closest as? [String: Any])? ["available"] as? Bool
        let status = (closest as? [String: Any])? ["status"] as? String
        let url = (closest as? [String: Any])? ["url"] as? String
        
        if (results != nil &&
            results_first != nil &&
            archived_snapshots != nil &&
            closest != nil &&
            available != nil &&
            available == true &&
            status == "200" &&
            isValidSnapshotUrl(url: url)
            ) {
            return url!
        } else {
            return nil
        }
        
    }
    
    func isValidSnapshotUrl(url: String?) -> Bool {
        if (url == nil) {
            return false
        }
        
        if (url!.range(of: "http://") != nil || (url!.range(of: "https://") != nil)) {
            return true
        } else {
            return false
        }
    }
    
    func getOriginalURL(url: String) -> String {
        var originalURL:String? = nil
        let tempArray = url.components(separatedBy: "http")
        if (tempArray.count > 2) {
            originalURL = "http" + tempArray[2]
        } else {
            originalURL = url
        }
        
        return originalURL!
    }
    
}
