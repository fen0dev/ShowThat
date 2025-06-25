//
//  AlertAction.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct AlertAction {
    let title: String
    let style: Style
    let action: (() -> Void)?
    
    enum Style {
        case primary
        case secondary
        case destructive
    }
    
    init(title: String, style: Style = .primary, action: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.action = action
    }
}
