//
//  WMConstants.swift
//  Wayback Machine
//
//  Created by Admin on 10/1/18.
//

import Cocoa

let VERSION = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
let BaseURL = "https://web.archive.org"
let SPN2URL = "https://web-beta.archive.org/save/"
let WebLoginURL = "https://archive.org/account/login.php"
let AvailabilityAPIURL = "https://archive.org/wayback/available"
let SupportURL = "https://archive.org/about/contact.php"
let HTTPFailCodes = [404, 408, 410, 451, 500, 502, 503, 504, 509, 520, 521, 523, 524, 525, 526]
