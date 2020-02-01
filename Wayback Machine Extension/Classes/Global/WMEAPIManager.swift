//
//  WMEAPIManager.swift
//  Wayback Machine Extension
//
//  Created by admin on 7/7/19.
//

import Foundation
import Alamofire

public enum WMCaptureOption {
    case allErrors, outlinks, screenshot
}
public typealias WMCaptureOptions = [WMCaptureOption]

class WMEAPIManager: NSObject {
    static let shared = WMEAPIManager()

    /// Checks Wayback Machine if given `url` has been archived.
    /// - parameter url: The URL to check.
    /// - parameter completion: Callback function.
    /// - parameter waybackURL: The URL as stored in the Wayback Machine, else `nil` if error or no response.
    /// - parameter retURL: The original URL passed in.

    func wmAvailabilityCheck(url: String, completion: @escaping (_ waybackURL: String?, _ retURL: String) -> Void) {

        // prepare request
        let requestParams = "url=\(url)"
        var request = URLRequest(url: URL(string: AvailabilityAPIURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        request.setValue("2", forHTTPHeaderField: "Wayback-Api-Version")
        request.setValue("Wayback_Machine_Safari_XC/\(APP_VERSION)", forHTTPHeaderField: "User-Agent")
        request.httpBody = requestParams.data(using: .utf8)

        // call API
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 { return }
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

    /// Returns true if `url` is a valid website URL.
    func isValidSnapshotUrl(url: String?) -> Bool {
        if (url == nil) { return false }
        if (url!.range(of: "http://") != nil || (url!.range(of: "https://") != nil)) {
            return true
        } else {
            return false
        }
    }

    func getSearchResult(url: String, completion: @escaping ([Any]) -> Void) {
        let url = "https://web.archive.org/cdx/search/cdx?url=\(url)/&fl=timestamp,original&matchType=prefix&filter=statuscode:200&filter=mimetype:text/html&output=json"
        
        Alamofire.request(url, method: .get)
            .responseJSON { (response) in
                switch response.result {
                case .success(let data):
                    completion(data as! [Any])   // FIXME: as!
                case .failure(let error):
                    NSLog("*** ERROR: %@", error.localizedDescription)
                    completion([])
                }
        }
    }
    
    func requestCapture(url: String, logged_in_user: HTTPCookie, logged_in_sig: HTTPCookie,
                        options: WMCaptureOptions, completion: @escaping (String?) -> Void) {

        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_user)
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_sig)

        var param = ["url" : url]
        if options.contains(.allErrors)  { param["capture_all"] = "1" }  // page with errors (status=4xx or 5xx)
        if options.contains(.outlinks)   { param["capture_outlinks"] = "1" }  // web page outlinks
        if options.contains(.screenshot) { param["capture_screenshot"] = "1" }  // full page screenshot as PNG

        let headers = [
            "Accept": "application/json",
            "User-Agent": "Wayback_Machine_Safari_XC/\(APP_VERSION)",
            "Wayback-Extension-Version": "Wayback_Machine_Safari_XC/\(APP_VERSION)"
        ]
        
        Alamofire.request(SPN2URL,
                          method: .post,
                          parameters: param,
                          headers: headers)
            .responseJSON{ (response) in
                
                switch response.result {
                case .success:
                    if let json = response.result.value as? [String: Any],
                        let job_id = json["job_id"] as? String {
                        completion(job_id)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    NSLog("*** ERROR: %@", error.localizedDescription)
                    completion(nil)
                }
        }
    }
    
    func requestCaptureStatus(job_id: String, logged_in_user: HTTPCookie, logged_in_sig: HTTPCookie, completion: @escaping (String?, String?) -> Void) {
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_user)
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_sig)
        
        let param = ["job_id" : job_id]
        let headers = [
            "Accept": "application/json",
            "User-Agent": "Wayback_Machine_Safari_XC/\(APP_VERSION)",
            "Wayback-Extension-Version": "Wayback_Machine_Safari_XC/\(APP_VERSION)"
        ]
        
        Alamofire.request("\(SPN2URL)status/",
            method: .post,
            parameters: param,
            headers: headers)
            .responseJSON{ (response) in
                
                switch response.result {
                case .success:
                    if let json = response.result.value as? [String: Any],
                        let status = json["status"] as? String {
                        // status is one of {"success", "pending", "error"}
                        if status == "pending" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                self.requestCaptureStatus(job_id: job_id, logged_in_user: logged_in_user, logged_in_sig: logged_in_sig, completion: completion)
                            })
                        } else if status == "success" {
                            if let timestamp = json["timestamp"] as? String,
                                let original_url = json["original_url"] as? String {
                                completion("http://web.archive.org/web/\(timestamp)/\(original_url)", nil)
                            } else {
                                completion(nil, "Unknown Status Error 1")
                            }
                        } else if status == "error" {
                            completion(nil, (json["message"] as? String) ?? "Unknown Status Error 2")
                        } else {
                            completion(nil, "Unknown Status Error 3 (\(status))")
                        }
                    } else {
                        completion(nil, "Error serializing JSON: \(String(describing: response.result.value))")
                    }
                case .failure(let error):
                    completion(nil, error.localizedDescription)
                }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (HTTPCookie?, HTTPCookie?) -> Void) {
        NSLog("*** WMEAPIManager.login()")  // DEBUG

        var params = [String: Any]()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"
        
        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.version: 0,
            HTTPCookiePropertyKey.name: "test-cookie",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: "1",
            HTTPCookiePropertyKey.domain: ".archive.org",
            HTTPCookiePropertyKey.secure: false,
            HTTPCookiePropertyKey.expires: NSDate(timeIntervalSinceNow: 86400 * 20)
        ]
        
        if let cookie = HTTPCookie(properties: cookieProps) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
        
        Alamofire.request(WebLoginURL, method: .post, parameters: params, encoding: URLEncoding.default, headers: ["Content-Type": "application/x-www-form-urlencoded"]).responseString{ (response) in
            
            switch response.result {
            case .success:
                var loggedInUser: HTTPCookie? = nil
                var loggedInSig: HTTPCookie? = nil
                
                if let cookies = HTTPCookieStorage.shared.cookies {
                    for cookie in cookies {
                        if cookie.name == "logged-in-sig" {
                            loggedInSig = cookie
                        } else if cookie.name == "logged-in-user" {
                            loggedInUser = cookie
                        }
                    }
                }
                
                completion(loggedInUser, loggedInSig)
            case .failure:
                completion(nil, nil)
            }
        }
    }
    
}
