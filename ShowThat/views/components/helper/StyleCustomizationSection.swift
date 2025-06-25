//
//  StyleCustomizationSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import PhotosUI

struct StyleCustomizationSection: View {
    @Binding var style: QRStyle
    @Binding var logoImage: UIImage?
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Style & Design", systemImage: "paintbrush")
                .font(.headline)
            
            // Design Style Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QRStyle.QRDesignStyle.allCases, id: \.self) { design in
                        DesignStyleCard(
                            design: design,
                            isSelected: style.design == design,
                            action: { style.design = design }
                        )
                    }
                }
            }
            
            // Color customization for branded style
            if style.design == .branded {
                VStack(spacing: 15) {
                    ColorPickerRow(
                        title: "QR Color",
                        selectedColor: Binding(
                            get: { style.foregroundColor.color },
                            set: { style.foregroundColor = CodableColor(color: $0) }
                        ),
                        icon: "paintpalette.fill"
                    )
                    
                    ColorPickerRow(
                        title: "Background",
                        selectedColor: Binding(
                            get: { style.backgroundColor.color },
                            set: { style.backgroundColor = CodableColor(color: $0) }
                        ),
                        icon: "square.fill.on.square.fill"
                    )
                    
                    // Logo Upload
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Image(systemName: logoImage == nil ? "photo.badge.plus" : "photo.fill.on.rectangle.fill")
                                .font(.title3)
                            
                            Text(logoImage == nil ? "Add Logo" : "Logo Added")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if logoImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    StyleCustomizationSection(style: .constant(QRStyle()), logoImage: .constant(.actions), showingImagePicker: .constant(false))
}
