// LicensesView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// View for displaying third-party licenses
struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Sample third-party dependencies - replace with actual dependencies
    let licenses = [
        License(name: "Firebase", type: "Apache 2.0", url: "https://github.com/firebase/firebase-ios-sdk"),
        License(name: "SwiftUI", type: "Apple", url: "https://developer.apple.com/xcode/swiftui/"),
        License(name: "Combine", type: "Apple", url: "https://developer.apple.com/documentation/combine")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                List {
                    ForEach(licenses) { license in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(license.name)
                                .font(Theme.Typography.bodyFontSystem.bold())
                                .foregroundStyle(Theme.Colors.text)
                            
                            Text("License: \(license.type)")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            
                            Link("View Source", destination: URL(string: license.url)!)
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Third-Party Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Represents a third-party license
struct License: Identifiable {
    var id = UUID()
    let name: String
    let type: String
    let url: String
}

#Preview {
    LicensesView()
}
