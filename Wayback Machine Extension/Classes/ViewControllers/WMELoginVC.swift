//
//  WMELoginVC.swift
//  Wayback Machine Extension
//
//  Created by admin on 7/7/19.
//

import Cocoa

class WMELoginVC: WMEBaseVC {
    
    static let shared: WMELoginVC = {
        NSLog("*** WMELoginVC.shared")  // DEBUG
        //let shared = WMELoginVC()
        return WMELoginVC()
        //return WMELoginVC.init(nibName: "WMELoginVC", bundle: nil)
    }()
    
    @IBOutlet weak var txtEmail: NSTextField!
    @IBOutlet weak var txtPassword: NSTextField!
    @IBOutlet weak var btnLogin: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.btnLogin.isEnabled = true
        loginEnable(true)
    }

    override func viewDidAppear() {
        //self.btnLogin.isEnabled = true
        loginEnable(true)
    }

    func loginEnable(_ enable:Bool) {
        if enable {
            btnLogin.title = "Log In"
            btnLogin.isEnabled = true
        } else {
            // TODO: animate?
            btnLogin.title = "Please Wait..."
            btnLogin.isEnabled = false
        }
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

        loginEnable(false)
        //self.btnLogin.isEnabled = false
        WMEAPIManager.shared.login(email: email, password: password) { (loggedInUser, loggedInSig) in

            self.loginEnable(true)
            //self.btnLogin.isEnabled = true
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
            
            //let mainVC = WMEMainVC.init(nibName: "WMEMainVC", bundle: nil)
            //self.view.window?.contentViewController = mainVC
            self.view.window?.contentViewController = WMEMainVC()
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
        //let aboutVC = WMEAboutVC.init(nibName: "WMEAboutVC", bundle: nil)
        self.view.window?.contentViewController = WMEAboutVC()
    }

}
