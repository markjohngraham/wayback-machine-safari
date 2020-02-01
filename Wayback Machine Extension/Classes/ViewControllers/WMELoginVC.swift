//
//  WMELoginVC.swift
//  Wayback Machine Extension
//
//  Created by admin on 7/7/19.
//

import Cocoa

class WMELoginVC: WMEBaseVC {
    
    static let shared: WMELoginVC = {
        return WMELoginVC()
    }()
    
    @IBOutlet weak var txtEmail: NSTextField!
    @IBOutlet weak var txtPassword: NSTextField!
    @IBOutlet weak var btnLogin: NSButton!

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        enableLogin(true)
    }

    override func viewDidAppear() {
        enableLogin(true)
    }

    func enableLogin(_ enable:Bool) {
        if enable {
            btnLogin.title = "Log In"
            btnLogin.isEnabled = true
        } else {
            // TODO: animate?
            btnLogin.title = "Please Wait..."
            btnLogin.isEnabled = false
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Actions

    @IBAction func loginClicked(_ sender: Any) {

        let email = txtEmail.stringValue
        let password = txtPassword.stringValue

        if email.isEmpty {
            WMEUtil.shared.showMessage(msg: "Email is required", info: "Please type an email.")
            return
        }
        if password.isEmpty {
            WMEUtil.shared.showMessage(msg: "Password is required", info: "Please type a password.")
            return
        }

        enableLogin(false)

        /* TODO: REMOVE
        WMEAPIManager.shared.login(email: email, password: password) { (loggedInUser, loggedInSig) in

            self.enableLogin(true)
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
            self.view.window?.contentViewController = WMEMainVC()
        }
        */

        WMSAPIManager.shared.login(email: email, password: password) { (userData) in
            self.enableLogin(true)
            if let userData = userData {
                // success
                WMEGlobal.shared.saveUserData(userData: userData)
                self.view.window?.contentViewController = WMEMainVC()
            } else {
                // failure
                WMEUtil.shared.showMessage(msg: "Login failed", info: "Either the connection failed, or your email or password were incorrect.")
            }
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
        self.view.window?.contentViewController = WMEAboutVC()
    }

}
