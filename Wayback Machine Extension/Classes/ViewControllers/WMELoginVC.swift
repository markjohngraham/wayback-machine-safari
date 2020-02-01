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
        txtEmail.delegate = self
        enableLogin(true)
    }

    // doesn't get called every time displayed
    override func viewWillAppear() {
        super.viewWillAppear()
        enableLogin(true)
        loadEmailField()
    }

    // viewWillDisappear() and viewDidDisappear() aren't called

    ///////////////////////////////////////////////////////////////////////////////////
    // MARK: - Helper Functions

    func enableLogin(_ enable:Bool) {
        if enable {
            btnLogin.title = "Log In"
            btnLogin.isEnabled = true
        } else {
            btnLogin.title = "Please Wait..."
            btnLogin.isEnabled = false
        }
    }

    func loadEmailField() {
        let userData = WMEGlobal.shared.getUserData()
        if let email = userData?["email"] as? String {
            txtEmail.stringValue = email
        }
    }

    func saveEmailField(text: String?) {
        if var userData = WMEGlobal.shared.getUserData() {
            userData["email"] = text
            WMEGlobal.shared.saveUserData(userData: userData)
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
        WMSAPIManager.shared.login(email: email, password: password) { (userData) in
            self.enableLogin(true)
            if let userData = userData {
                // success
                WMEGlobal.shared.saveUserData(userData: userData)
                self.view.window?.contentViewController = WMEMainVC()
            } else {
                // failure
                WMEUtil.shared.showMessage(msg: "Login Failed", info: "Either the connection failed, or your email or password were incorrect.")
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

///////////////////////////////////////////////////////////////////////////////////
// MARK: -

extension WMELoginVC: NSTextFieldDelegate {

    func controlTextDidEndEditing(_ obj: Notification) {
        saveEmailField(text: txtEmail.stringValue)
    }

}
