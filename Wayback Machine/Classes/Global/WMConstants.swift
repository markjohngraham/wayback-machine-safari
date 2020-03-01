//
//  WMConstants.swift
//  Wayback Machine
//
//  Created by Admin on 10/1/18.
//

import Cocoa

let APP_VERSION = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
let APP_BUILD = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
let DEBUG_LOG = false

let SupportURL = "https://archive.org/about/contact.php"
let HTTPFailCodes = [404, 408, 410, 451, 500, 502, 503, 504, 509, 520, 521, 523, 524, 525, 526]
