//
//  WMELoginVC.swift
//  Wayback Machine Extension
//
//  Created by admin on 7/7/19.
//

import Cocoa

class WMELoginVC: WMEBaseVC {
    
    static let shared: WMELoginVC = {
        let shared = WMELoginVC()
        return shared
    }()
    
    @IBOutlet weak var txtEmail: NSTextField!
    @IBOutlet weak var txtPassword: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        if txtEmail.stringValue.isEmpty {
            WMEUtil.shared.showMessage(msg: "Email is required", info: "Please type an email")
            return
        }
        
        if txtPassword.stringValue.isEmpty {
            WMEUtil.shared.showMessage(msg: "Password is required", info: "Please type a password")
            return
        }
        
        let email = txtEmail.stringValue
        let password = txtPassword.stringValue
        
        WMEAPIManager.shared.login(email: email, password: password) { (loggedInUser, loggedInSig) in
            guard let loggedInUser = loggedInUser, let loggedInSig = loggedInSig else {
                WMEUtil.shared.showMessage(msg: "Login failed", info: "Email or password is not valid")
                return
            }
            
            WMEGlobal.shared.saveUserData(userData: [
                "email": email,
                "password": password,
                "logged-in-user": loggedInUser,
                "logged-in-sig": loggedInSig,
                "logged-in": true
            ])
            
            let mainVC = WMEMainVC.init(nibName: "WMEMainVC", bundle: nil)
            self.view.window?.contentViewController = mainVC
        }
    }

    /// Opens the sign up webpage.
    @IBAction func signupClicked(_ sender: Any) {
        WMEUtil.shared.openTabWithURL(url: "https://archive.org/account/signup?referer=SafariExtension")
    }

    /// Opens the forgot password webpage.
    @IBAction func forgotPasswordClicked(_ sender: Any) {
        WMEUtil.shared.openTabWithURL(url: "https://archive.org/account/forgot-password")
    }

    /// Go to About view
    @IBAction func aboutClicked(_ sender: Any) {
        let aboutVC = WMEAboutVC.init(nibName: "WMEAboutVC", bundle: nil)
        self.view.window?.contentViewController = aboutVC
    }

}
