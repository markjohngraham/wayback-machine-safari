//
//  WMConstants.swift
//  Wayback Machine
//
//  Created by Admin on 10/1/18.
//

import Cocoa

let VERSION = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
let BaseURL = "https://web.archive.org"
let AvailabilityAPIURL = "https://archive.org/wayback/available"
let HTTPFailCodes = [404, 408, 410, 451, 500, 502, 503, 504, 509, 520, 521, 523, 524, 525, 526]
