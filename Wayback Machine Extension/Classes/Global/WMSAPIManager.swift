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
/// - DEBUG_LOG

class WMSAPIManager {
    static let shared = WMSAPIManager()

    public enum CaptureOption {
        case allErrors, outlinks, screenshot, availability
    }
    public typealias CaptureOptions = [CaptureOption]

    // MARK: - API Constants

    // keep base URLs as vars to support testing
    static var WM_BASE_URL         = "https://web.archive.org"
    static let WM_SPN2_SAVE        = "/save/"
    static let WM_SPN2_STATUS      = "/save/status/"
    static let WM_OLDEST           = "/web/0/"
    static let WM_NEWEST           = "/web/2/"
    static let WM_OVERVIEW         = "/web/*/"

    static var WEB_BASE_URL        = "https://archive.org"
    static let WEB_AVAILABILITY    = "/wayback/available"
    static let WEB_LOGIN           = "/account/login"
    static let WEB_S3KEYS          = "/account/s3.php?output_json=1"

    static var UPLOAD_BASE_URL     = "https://s3.us.archive.org"

    /// update headers to reflect different apps
    static let HEADERS: HTTPHeaders = [
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

    /// Sets a temporary cookie for the archive.org domain and its sub-domains.
    func setArchiveCookie(name: String, value: String) {
        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.name: name,
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.domain: ".archive.org",
            HTTPCookiePropertyKey.secure: true,
            HTTPCookiePropertyKey.discard: true
        ]
        if let cookie = HTTPCookie(properties: cookieProps) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Login API

    /// Main Login that uses a 2-step API call to retrieve the S3 keys given a user's email and password.
    /// - parameter email: User's email.
    /// - parameter password: User's password.
    /// - parameter completion: Returns a Dictionary to pass to saveUserData(), else nil if failed.
    /// - returns: *Keys*:
    ///   email, logged-in-user, logged-in-sig, s3accesskey, s3secretkey
    ///
    func login(email: String, password: String, completion: @escaping ([String: Any?]?) -> Void) {

        webLogin(email: email, password: password) {
            (loggedInUser, loggedInSig) in

            if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
                self.getIAS3Keys(loggedInUser: loggedInUser, loggedInSig: loggedInSig) {
                    (accessKey, secretKey) in

                    if let accessKey = accessKey, let secretKey = secretKey {
                        // success
                        let data: [String: Any?] = [
                            // password not stored
                            "email"          : email,
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

    /// Login using the web login form, which returns cookie strings that may be used
    /// for short-term auth. For longer-term, retrieve the A3 keys using getIAS3Keys().
    /// See login().
    ///
    func webLogin(email: String, password: String,
                  completion: @escaping (_ loggedInUser: String?, _ loggedInSig: String?) -> Void) {

        // prepare cookie to avoid glitch where login doesn't work half the time.
        setArchiveCookie(name: "test-cookie", value: "1")

        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        var params = Parameters()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"

        // make login request
        Alamofire.request(WMSAPIManager.WEB_BASE_URL + WMSAPIManager.WEB_LOGIN,
                          method: .post, parameters: params, headers: headers)
        .responseString { (response) in

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

    /// Get the S3 account keys for long-term API access. Pass in cookie strings returned by webLogin().
    ///
    func getIAS3Keys(loggedInUser: String, loggedInSig: String,
                     completion: @escaping (_ accessKey: String?, _ secretKey: String?) -> Void) {

        // prepare cookies
        setArchiveCookie(name: "logged-in-user", value: loggedInUser)
        setArchiveCookie(name: "logged-in-sig", value: loggedInSig)

        // make request
        Alamofire.request(WMSAPIManager.WEB_BASE_URL + WMSAPIManager.WEB_S3KEYS,
                          method: .get, parameters: nil, headers: WMSAPIManager.HEADERS)
        .responseJSON { (response) in

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
    // Get additional info such as user's screenname.
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
        if (DEBUG_LOG) { NSLog("*** checkAvailability() url: \(url)") }

        // prepare request
        let requestParams = "url=\(url)"
        var request = URLRequest(url: URL(string: WMSAPIManager.WEB_BASE_URL + WMSAPIManager.WEB_AVAILABILITY)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        for (key, value) in WMSAPIManager.HEADERS {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = requestParams.data(using: .utf8)

        // make request
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in

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

    /// Retrieves data for the Site Map graph.
    func getSiteMapData(url: String, completion: @escaping (_ data: [Any]?) -> Void) {

        // TODO: need to check/encode url?
        let apiURL = "https://web.archive.org/cdx/search/cdx?url=\(url)/&fl=timestamp,original&matchType=prefix&filter=statuscode:200&filter=mimetype:text/html&output=json"

        /* TODO: later
        // prepare request
        var params = Parameters()
        params["url"] = url
        params["fl"] = "timestamp,original"
        params["matchType"] = "prefix"
        //params["filter"] = "statuscode:200"  // need to handle multiple values for same key
        //params["filter"] = "mimetype:text/html"
        params["output"] = "json"
        // */

        // make request
        Alamofire.request(apiURL, method: .get, headers: WMSAPIManager.HEADERS)
        .responseJSON { (response) in
            switch response.result {
            case .success(let data):
                //if let json = response.result.value as? [String: Any]  // ??
                completion(data as? [Any])
            case .failure(let error):
                NSLog("*** ERROR: %@", error.localizedDescription)
                completion(nil)
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Save Page Now API (SPN2)

    // WAS: requestCapture(...)
    /// Requests Wayback Machine to save the given webpage using cookie auth.
    /// - parameter url: Can be a full or partial URL with or without the http(s).
    /// - parameter loggedInUser: Cookie string for short-term auth.
    /// - parameter loggedInSig: Cookie string for short-term auth.
    /// - parameter options: See enum & API docs for options.
    /// - parameter jobId: Returns a job ID to pass to getPageStatus() for status updates.
    ///
    func capturePage(url: String, loggedInUser: String, loggedInSig: String, options: CaptureOptions = [],
                     completion: @escaping (_ jobId: String?) -> Void) {

        // prepare cookies
        setArchiveCookie(name: "logged-in-user", value: loggedInUser)
        setArchiveCookie(name: "logged-in-sig", value: loggedInSig)
        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        capturePage(url: url, headers: headers, options: options, completion: completion)
    }

    /// Requests Wayback Machine to save the given webpage using S3 auth.
    /// - parameter url: Can be a full or partial URL with or without the http(s).
    /// - parameter accessKey: String for long-term S3 auth.
    /// - parameter secretKey: String for long-term S3 auth.
    /// - parameter options: See enum & API docs for options.
    /// - parameter jobId: Returns a job ID to pass to getPageStatus() for status updates.
    ///
    func capturePage(url: String, accessKey: String, secretKey: String, options: CaptureOptions = [],
                     completion: @escaping (_ jobId: String?) -> Void) {

        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        headers["Authorization"] = "LOW \(accessKey):\(secretKey)"
        capturePage(url: url, headers: headers, options: options, completion: completion)
    }

    /// Requests Wayback Machine to save the given webpage. Requires manually setting headers.
    /// Better to call the other functions directly.
    ///
    func capturePage(url: String, headers: HTTPHeaders, options: CaptureOptions = [],
                     completion: @escaping (_ jobId: String?) -> Void) {

        // prepare request
        var params = Parameters()
        params["url"] = url
        if options.contains(.allErrors)  { params["capture_all"] = "1" }  // page with errors (status=4xx or 5xx)
        if options.contains(.outlinks)   { params["capture_outlinks"] = "1" }  // web page outlinks
        if options.contains(.screenshot) { params["capture_screenshot"] = "1" }  // full page screenshot as PNG

        // make request
        Alamofire.request(WMSAPIManager.WM_BASE_URL + WMSAPIManager.WM_SPN2_SAVE,
                          method: .post, parameters: params, headers: headers)
        .responseJSON { (response) in

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

    /// Use to retrieve status of saving a page in the Wayback Machine.
    /// Provide `loggedInUser` & `loggedInSig` to use cookie auth.
    /// Or `accessKey` & `secretKey` to use S3 auth. Must pick one or the other.
    /// - parameter jobId: ID from capturePage().
    /// - parameter loggedInUser: Cookie string for short-term auth.
    /// - parameter loggedInSig: Cookie string for short-term auth.
    /// - parameter accessKey: String for long-term S3 auth.
    /// - parameter secretKey: String for long-term S3 auth.
    /// - parameter options: Normally leave off.
    /// - parameter resources: Array of Strings of URLs that the Wayback Machine archived.
    /// - parameter archiveURL: URL of archived website on the Wayback Machine, or `nil` if error.
    /// - parameter errMsg: Error message as String.
    ///
    func getPageStatus(jobId: String,
                       loggedInUser: String? = nil, loggedInSig: String? = nil,
                       accessKey: String? = nil, secretKey: String? = nil,
                       options: CaptureOptions = [],
                       pending: @escaping (_ resources: [String]?) -> Void = {_ in },
                       completion: @escaping (_ archiveURL: String?, _ errMsg: String?) -> Void)
    {
        if (DEBUG_LOG) { NSLog("*** getPageStatus()") }

        // prepare cookies
        if let loggedInUser = loggedInUser, let loggedInSig = loggedInSig {
            setArchiveCookie(name: "logged-in-user", value: loggedInUser)
            setArchiveCookie(name: "logged-in-sig", value: loggedInSig)
        }
        // prepare request
        var headers = WMSAPIManager.HEADERS
        headers["Accept"] = "application/json"
        if let accessKey = accessKey, let secretKey = secretKey {
            headers["Authorization"] = "LOW \(accessKey):\(secretKey)"
        }
        var params = Parameters()
        params["job_id"] = jobId
        if options.contains(.availability) { params["outlinks_availability"] = "1" }  // outlinks contain timestamps (NOT USED)

        // TODO: return custom Error objects?

        // make request
        Alamofire.request(WMSAPIManager.WM_BASE_URL + WMSAPIManager.WM_SPN2_STATUS,
                          method: .post, parameters: params, headers: headers)
        .responseJSON { (response) in
            switch response.result {
            case .success:
                if let json = response.result.value as? [String: Any],
                    let status = json["status"] as? String {
                    // status is one of {"success", "pending", "error"}
                    if (DEBUG_LOG) { NSLog("*** SPN2 Status: \(status)") }
                    if status == "pending" {
                        pending(json["resources"] as? [String])
                        // TODO: May need to allow for cancel or timeout.
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            self.getPageStatus(jobId: jobId, loggedInUser: loggedInUser, loggedInSig: loggedInSig,
                                               accessKey: accessKey, secretKey: secretKey, options: options,
                                               pending: pending, completion: completion)
                        }
                    } else if status == "success" {
                        if let timestamp = json["timestamp"] as? String,
                            let originalUrl = json["original_url"] as? String {
                            let archiveUrl = WMSAPIManager.WM_BASE_URL + "/web/\(timestamp)/\(originalUrl)"
                            completion(archiveUrl, nil)
                        } else {
                            completion(nil, "Unknown Status Error 1")
                        }
                    } else if status == "error" {
                        let message = json["message"] as? String ?? "Unknown Status Error 2"
                        completion(nil, message)
                    } else {
                        completion(nil, "Unknown Status Error 3 (\(status))")
                    }
                } else {
                    completion(nil, "Error serializing JSON: \(String(describing: response.result.value))")
                }

            case .failure(let error):
                // Sometimes we get "The request timed out".
                // This error really should be fixed on the server API end.
                if (DEBUG_LOG) { NSLog("*** getPageStatus(): request failure: " + error.localizedDescription) }
                completion(nil, error.localizedDescription)
            }
        }
    }

}
