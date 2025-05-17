// AboutView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI
import Foundation

/// About view showing app information
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    @State private var showingPrivacyTerms = false
    @State private var privacyTermsInitialTab = 0 // 0 for Privacy, 1 for Terms
    @State private var showingLicenses = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App logo
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.top, 24)
                        
                        // App name and version
                        VStack(spacing: 4) {
                            Text("MyChores")
                                .font(Theme.Typography.titleFontSystem)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.bottom, 32)
                        
                        // Information section
                        VStack(spacing: 16) {
                            infoRow(title: "Developer", value: "Chores App Team")
                            infoRow(title: "Contact", value: "support@mychoresapp.com")
                            infoRow(title: "Website", value: "www.mychoresapp.com")
                            
                            Button {
                                privacyTermsInitialTab = 0 // Privacy
                                showingPrivacyTerms = true
                            } label: {
                                infoRow(title: "Privacy Policy", value: "")
                            }
                            
                            Button {
                                privacyTermsInitialTab = 1 // Terms
                                showingPrivacyTerms = true
                            } label: {
                                infoRow(title: "Terms of Service", value: "")
                            }
                            
                            Button {
                                showLicenses()
                            } label: {
                                infoRow(title: "Open Source Licenses", value: "")
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Copyright
                        Text("© 2025 MyChores App Team. All rights reserved.")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(.top, 32)
                            .padding(.bottom, 16)
                    }
                }
                .navigationTitle("About")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingPrivacyTerms) {
                    PrivacyTermsView()
                }
                .sheet(isPresented: $showingLicenses) {
                    LicensesView()
                }
            }
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.bodyFontSystem)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func showLicenses() {
        showingLicenses = true
    }
}

#Preview {
    AboutView()
}

#Preview("Licenses") {
    LicensesView()
}
