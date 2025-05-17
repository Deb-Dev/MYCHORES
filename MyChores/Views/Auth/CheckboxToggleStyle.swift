// CheckboxToggleStyle.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(configuration.isOn ? Theme.Colors.primary : Color.gray.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(configuration.isOn ? Theme.Colors.primary.opacity(0.1) : Color.clear)
                    )
                
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
            
            configuration.label
                .padding(.leading, 4)
        }
    }
}

#Preview {
    VStack {
        Toggle("Remember me", isOn: .constant(true))
            .toggleStyle(CheckboxToggleStyle())
        
        Toggle("Accept terms", isOn: .constant(false))
            .toggleStyle(CheckboxToggleStyle())
    }
    .padding()
}
