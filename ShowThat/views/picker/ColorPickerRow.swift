//
//  ColorPickerRow.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI

struct ColorPickerRow: View {
    let title: String
    @Binding var selectedColor: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(selectedColor)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            ColorPicker("", selection: $selectedColor)
                .labelsHidden()
                .scaleEffect(1.2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ColorPickerRow(title: "Test", selectedColor: .constant(.pink), icon: "globe")
}
