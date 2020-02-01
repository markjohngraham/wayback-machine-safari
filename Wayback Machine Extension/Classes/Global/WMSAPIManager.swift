//
//  WMSAPIManager.swift
//  Wayback Machine Shared
//
//  Created by Carl on 1/28/20.
//
//  This code is meant to be shared across the Safari Extension, iOS, and TV apps.
//  Any modifications should be synced across apps.

import Foundation
import Alamofire

/// # Globals Used #
/// - APP_VERSION

class WMSAPIManager {
    static let shared = WMSAPIManager()

    // MARK: - API Constants

    // keep base URLs as vars to support testing
    var WM_BASE_URL         = "https://web.archive.org"
    let WM_SPN2             = "/save/"

    var WEB_BASE_URL        = "https://archive.org"
    let WEB_AVAILABILITY    = "/wayback/available"
    let WEB_LOGIN           = "/account/login"
    let WEB_S3KEYS          = "/account/s3.php?output_json=1"

    let UPLOAD_BASE_URL     = "https://s3.us.archive.org"

    /// update headers to reflect different apps
    let HEADERS: HTTPHeaders = [
        "User-Agent": "Wayback_Machine_Safari_XC/\(APP_VERSION)",
        "Wayback-Extension-Version": "Wayback_Machine_Safari_XC/\(APP_VERSION)",
        "Wayback-Api-Version": "2"
    ]


    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Helper Functions

    // WAS: func isValidSnapshotUrl(url: String?) -> Bool
    /// Returns true if `url` is a valid website URL, i.e. it begins with `http(s)://`.
    func isValidWebURL(_ url: String?) -> Bool {
        guard let url = url else { return false }
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }

    // WAS: func getURL(url: String) -> String
    /// Given a `url` string, prepends `https://` if `http(s)://` isn't present.
    func fullWebURL(_ url: String) -> String {
        return isValidWebURL(url) ? url : "https://\(url)"
    }


    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Login API

    /// Main Login that uses a 2-step API call to retrieve the S3 keys given a user's email and password.
    /// - parameter email: User's email.
    /// - parameter password: User's password.
    /// - parameter completion: Returns a Dictionary to pass to saveUserData(), else nil if failed.
    /// - returns: *Keys*:
    ///   email, password, logged-in-user, logged-in-sig, s3accesskey, s3secretkey, screenname (not yet)
    ///
    func login(email: String, password: String, completion: @escaping ([String: Any?]?) -> Void) {

        self.webLogin(email: email, password: password) {
            (loggedInUser, loggedInSig) in

            if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
                self.getIAS3Keys(loggedInUser: loggedInUser, loggedInSig: loggedInSig) {
                    (accessKey, secretKey) in

                    if let accessKey = accessKey, let secretKey = secretKey {
                        // success
                        let data: [String: Any?] = [
                            "email"          : email,
                            "password"       : password,    // FIXME: don't save pw
                            "logged-in-user" : loggedInUser,
                            "logged-in-sig"  : loggedInSig,
                            "s3accesskey"    : accessKey,
                            "s3secretkey"    : secretKey,
                            "logged-in"      : true
                        ]
                        completion(data)
                    } else {
                        // failed to get the S3 keys
                        completion(nil)
                    }
                }
            } else {
                // couldn't log in
                completion(nil)
            }
        }
    }

    /// Logout returns userData[] with key fields cleared, and `logged-in` set to false. Also clears cookies.
    ///
    func logout(userData: [String: Any?]?) -> [String: Any?]? {

        // clear cookies
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.removeCookies(since: Date.distantPast)
        if var udata = userData {
            udata["logged-in-user"] = nil
            udata["logged-in-sig"] = nil
            udata["s3accesskey"] = nil
            udata["s3secretkey"] = nil
            udata["logged-in"] = false
            return udata
        }
        return nil
    }

    // done, not tested
    func webLogin(email: String, password: String,
                  completion: @escaping (_ loggedInUser: String?, _ loggedInSig: String?) -> Void) {

        // prepare request
        var headers = HEADERS
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        var params = [String: Any]()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"
        /*
        // TODO: Test if following is necessary
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
        // */

        // make login request
        Alamofire.request(WEB_BASE_URL + WEB_LOGIN, method: .post, parameters: params, encoding: URLEncoding.default,
                          headers: headers).responseString { (response) in
            switch response.result {
            case .success:
                var ck = [String: String]()
                if let cookies = HTTPCookieStorage.shared.cookies {
                    for cookie in cookies {
                        ck[cookie.name] = cookie.value
                    }
                }
                completion(ck["logged-in-user"], ck["logged-in-sig"])

            case .failure:
                completion(nil, nil)
            }
        }
    }

    /// Get the S3 account keys.
    ///
    func getIAS3Keys(loggedInUser: String, loggedInSig: String,
                     completion: @escaping (_ accessKey: String?, _ secretKey: String?) -> Void) {

        // prepare cookies for request
        let cookiePropsLoggedInUser: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.name: "logged-in-user",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: loggedInUser,
            HTTPCookiePropertyKey.domain: ".archive.org"
        ]
        let cookiePropsLoggedInSig: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.name: "logged-in-sig",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: loggedInSig,
            HTTPCookiePropertyKey.domain: ".archive.org"
        ]
        if let cookieLoggedInUser = HTTPCookie(properties: cookiePropsLoggedInUser),
            let cookieLoggedInSig = HTTPCookie(properties: cookiePropsLoggedInSig) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookieLoggedInUser)
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookieLoggedInSig)
        }

        // make request
        Alamofire.request(WEB_BASE_URL + WEB_S3KEYS, method: .get, parameters: nil, encoding: URLEncoding.default,
                          headers: HEADERS).responseJSON { (response) in
            // API Response:
            // {"success":1,"key":{"s3accesskey":"...","s3secretkey":"..."}}
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any],
                    let key = json["key"] as? [String: String] {
                    completion(key["s3accesskey"], key["s3secretkey"])
                } else {
                    completion(nil, nil)
                }
            case .failure:
                completion(nil, nil)
            }
        }
    }

    // TODO: Get Account Info
    //func getAccountInfo(email: String, completion: @escaping ([String: Any]?) -> Void) {
    //    SendDataToService(params: ["email": email], operation: API_INFO, completion: completion)
    //}


    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Wayback API

    // WAS: func wmAvailabilityCheck(url: String, completion: @escaping (String?, String?) -> Void)
    /// Checks Wayback Machine if given `url` has been archived.
    /// - parameter url: The URL to check.
    /// - parameter completion: Callback function.
    /// - parameter waybackURL: The URL as stored in the Wayback Machine, else `nil` if error or no response.
    /// - parameter originalURL: The original URL passed in.
    ///
    func checkAvailability(url: String, completion: @escaping (_ waybackURL: String?, _ originalURL: String) -> Void) {

        // prepare request
        let requestParams = "url=\(url)"
        var request = URLRequest(url: URL(string: WEB_BASE_URL + WEB_AVAILABILITY)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        for (key, value) in HEADERS {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = requestParams.data(using: .utf8)

        // make request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                completion(self.extractWaybackURL(from: json), url)
            } catch _ {
                completion(nil, url)
            }
        }
        task.resume()
    }

    // WAS: func getWaybackUrlFromResponse(response: [String: Any]) -> String?
    /// Grabs the wayback URL string out of the JSON response object from checkAvailability().
    /// - parameter response: from JSONSerialization.jsonObject()
    /// - returns: Wayback URL as String, or nil if not available, invalid, or status != 200.
    ///
    /// # API response JSON format: #
    /// ```
    /// "results" : [ { "archived_snapshots": {
    ///   "closest": { "available": true, "status": "200", "url": "http:..." }
    /// } } ]
    /// ```
    func extractWaybackURL(from response: [String: Any]?) -> String? {

        if let results = response?["results"] as? [[String: Any]],
            let archived_snapshots = results.first?["archived_snapshots"] as? [String: Any],
            let closest = archived_snapshots["closest"] as? [String: Any],
            let available = closest["available"] as? Bool,
            let status = closest["status"] as? String,
            let url = closest["url"] as? String,
            available == true,
            status == "200",
            isValidWebURL(url)
        {
            return url
        }
       return nil
    }

}
