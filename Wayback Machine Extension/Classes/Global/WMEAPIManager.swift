//
//  WMEAPIManager.swift
//  Wayback Machine Extension
//
//  Created by admin on 7/7/19.
//

import Cocoa
import Alamofire

class WMEAPIManager: NSObject {
    static let shared = WMEAPIManager()
    
    func getSearchResult(url: String, completion: @escaping ([Any]) -> Void) {
        let url = "https://web.archive.org/cdx/search/cdx?url=\(url)/&fl=timestamp,original&matchType=prefix&filter=statuscode:200&filter=mimetype:text/html&output=json"
        
        Alamofire.request(url, method: .get)
            .responseJSON { (response) in
                switch response.result {
                case .success(let data):
                    completion(data as! [Any])
                case .failure(let error):
                    print(error.localizedDescription)
                    completion([])
                }
        }
    }
    
    func requestCapture(url: String, logged_in_user: HTTPCookie, logged_in_sig: HTTPCookie, completion: @escaping (String?) -> Void) {
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_user)
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(logged_in_sig)
        
        let param = ["url" : url]
        let headers = [
            "Accept": "application/json",
            "User-Agent": "Wayback_Machine_Safari_XC/\(VERSION)",
            "Wayback-Extension-Version": "Wayback_Machine_Safari_XC/\(VERSION)"
        ]
        
        Alamofire.request(SPN2URL,
                          method: .post,
                          parameters: param,
                          headers: headers)
            .responseJSON{ (response) in
                
                switch response.result {
                case .success(let data):
                    if let json = response.result.value as? [String: Any],
                        let job_id = json["job_id"] as? String {
                        completion(job_id)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
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
            "User-Agent": "Wayback_Machine_Safari_XC/\(VERSION)",
            "Wayback-Extension-Version": "Wayback_Machine_Safari_XC/\(VERSION)"
        ]
        
        Alamofire.request("\(SPN2URL)status/",
            method: .post,
            parameters: param,
            headers: headers)
            .responseJSON{ (response) in
                
                switch response.result {
                case .success(let data):
                    if let json = response.result.value as? [String: Any],
                        let status = json["status"] as? String {
                        
                        if status == "pending" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                self.requestCaptureStatus(job_id: job_id, logged_in_user: logged_in_user, logged_in_sig: logged_in_sig, completion: completion)
                            })
                        } else {
                            if let timestamp = json["timestamp"] as? String,
                                let original_url = json["original_url"] as? String {
                                completion("http://web.archive.org/web/\(timestamp)/\(original_url)", nil)
                            } else if let errorMessage = json["message"] as? String {
                                completion(nil, errorMessage)
                            } else {
                                completion(nil, json["status"] as? String)
                            }
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
