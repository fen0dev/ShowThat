//
//  WiFiData.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation

struct WiFiData: Codable {
    var ssid: String
    var password: String
    var encryption: String = "WPA"
    var isHidden: Bool = false
}
