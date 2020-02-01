//
//  WMEGlobal.swift
//  Wayback Machine Extension
//
//  Created by admin on 7/7/19.
//

import Foundation

class WMEGlobal: NSObject {
    static let shared = WMEGlobal()
    
    func saveUserData(userData: [String: Any?]) {
        let encodedObject = NSKeyedArchiver.archivedData(withRootObject: userData)
        UserDefaults.standard.set(encodedObject, forKey: "UserData")
        UserDefaults.standard.synchronize()
    }
    
    func getUserData() -> [String: Any?]? {
        if let encodedData = UserDefaults.standard.data(forKey: "UserData") {
            let obj = NSKeyedUnarchiver.unarchiveObject(with: encodedData)
            return obj as? [String: Any?]
        } else {
            return nil
        }
    }
    
    func isLoggedIn() -> Bool {
        if let userData = self.getUserData(),
            let isLoggedin = userData["logged-in"] as? Bool,
            isLoggedin == true {
            return true
        }
        return false
    }
}
