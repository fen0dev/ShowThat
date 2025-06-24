//
//  vCardData.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation

struct VCardData: Codable {
    var fullName: String
    var organization: String?
    var title: String?
    var phone: String?
    var email: String?
    var website: String?
    var linkedIn: String?
    var address: String?
    
    var vCardString: String {
        var vcard = "BEGIN:VCARD\nVERSION:3.0\n"
        vcard += "FN:\(fullName)\n"
        if let org = organization { vcard += "ORG:\(org)\n" }
        if let title = title { vcard += "TITLE:\(title)\n" }
        if let phone = phone { vcard += "TEL:\(phone)\n" }
        if let email = email { vcard += "EMAIL:\(email)\n" }
        if let website = website { vcard += "URL:\(website)\n" }
        if let address = address { vcard += "ADR:;;\(address)\n" }
        vcard += "END:VCARD"
        return vcard
    }
}
