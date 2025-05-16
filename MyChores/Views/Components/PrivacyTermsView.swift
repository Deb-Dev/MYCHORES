// PrivacyTermsView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// View to display the Privacy Policy and Terms of Service
struct PrivacyTermsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int
    
    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    Picker("", selection: $selectedTab) {
                        Text("Privacy Policy").tag(0)
                        Text("Terms of Service").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])
                    
                    // Tab content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if selectedTab == 0 {
                                privacyPolicyContent
                            } else {
                                termsOfServiceContent
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Privacy Policy" : "Terms of Service")
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
    
    // MARK: - Content Sections
    
    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section 1: Who We Are
            sectionHeader("1. Who We Are")
            
            Text("**MyChores** ('we', 'our', 'us') is a personal productivity application operated by **Debasish Chowdhury (sole proprietor)**, headquartered at **21 Ice Boat Terrace, Toronto, ON M5V 4A9, Canada**.")
                .font(Theme.Typography.bodyFontSystem)
            
            Text("Contact: **support@mychore.app**")
                .font(Theme.Typography.bodyFontSystem)
            
            // Section 2: Scope
            sectionHeader("2. Scope")
            
            Text("This Privacy Policy explains how we collect, use, disclose and safeguard your information when you use the MyChores iOS application and any related services (collectively, the 'Service').")
                .font(Theme.Typography.bodyFontSystem)
            
            // Section 3: Information We Collect
            sectionHeader("3. Information We Collect")
            
            Text("We collect only the information required to operate and improve MyChores:")
                .font(Theme.Typography.bodyFontSystem)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                bulletPoint("**Account Data** – email address, display name, and (optionally) your avatar.")
                bulletPoint("**Household & Chore Data** – household names, member user‑IDs, chores, points, and badges you generate while using the app.")
                bulletPoint("**Usage & Diagnostics** – device identifier, app version, crash logs, feature‑usage metrics, and Firebase Analytics events (collected automatically).")
                bulletPoint("**Push Tokens** – APNs / FCM tokens so we can deliver notifications to your device.")
            }
            
            Text("We do **not** knowingly collect sensitive personal data (e.g., biometric, health, or political information).")
                .font(Theme.Typography.bodyFontSystem)
                .padding(.top, 8)
                
            // Section 4: How We Use Your Information
            sectionHeader("4. How We Use Your Information")
            
            VStack(alignment: .leading, spacing: 12) {
                bulletPoint("Provide and maintain the Service (sync chores, leaderboards, badges)")
                bulletPoint("Send push notifications and in‑app messages")
                bulletPoint("Monitor performance, spot crashes and improve features")
                bulletPoint("Enforce our Terms of Service and protect against abuse")
            }
            
            // Section 5: Legal Bases
            sectionHeader("5. Legal Bases (GDPR)")
            
            legalBasesTable
            
            // Sections 6-13
            sectionHeader("6. Sharing & Disclosure")
            
            Text("We never sell your data. We share it only:")
                .font(Theme.Typography.bodyFontSystem)
                .padding(.bottom, 8)
                
            VStack(alignment: .leading, spacing: 12) {
                bulletPoint("**Firebase (Google LLC)** – hosting, authentication, push, analytics")
                bulletPoint("**Apple** – push notifications, in‑app purchases (future)")
            }
            
            Text("All processors are bound by GDPR‑compliant data‑processing agreements.")
                .font(Theme.Typography.bodyFontSystem)
                .padding(.top, 8)
            
            sectionHeader("7. Data Retention")
            
            VStack(alignment: .leading, spacing: 12) {
                bulletPoint("Account data: kept until you delete your account.")
                bulletPoint("Household & chore data: retained while household exists.")
                bulletPoint("Crash logs & analytics: 24 months rolling window.")
            }
            
            sectionHeader("8. Security")
            
            Text("Encryption in transit (HTTPS/TLS 1.2+). Firestore security rules restrict access to authenticated users in their household. App Check enforces trusted clients.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("9. Your Rights (EEA/UK residents)")
            
            Text("Access, rectification, erasure, restriction, objection, portability.\nTo exercise, email **support@mychore.app** with subject *Privacy Request*.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("10. Children")
            
            Text("Service is not directed to children under 13. If we learn we collected data from a child, we delete the account.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("11. International Transfers")
            
            Text("Data is stored on Google Cloud servers in **us-west1**. Google maintains Standard Contractual Clauses for transfers outside the EEA/UK.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("12. Changes")
            
            Text("We'll post any amendments in‑app and update the 'Last updated' date. Material changes require renewed consent where legally necessary.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("13. Contact")
            
            Text("Questions? **support@mychore.app**")
                .font(Theme.Typography.bodyFontSystem)
        }
    }
    
    private var termsOfServiceContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section 1: Acceptance
            sectionHeader("1. Acceptance")
            
            Text("By creating an account or using the Service you agree to these Terms and our Privacy Policy.")
                .font(Theme.Typography.bodyFontSystem)
            
            // Section 2: Eligibility
            sectionHeader("2. Eligibility")
            
            Text("You must be at least 13 years old and legally capable of forming a contract. Parents are responsible for minors' use.")
                .font(Theme.Typography.bodyFontSystem)
            
            // Section 3: Accounts & Households
            sectionHeader("3. Accounts & Households")
            
            VStack(alignment: .leading, spacing: 12) {
                bulletPoint("One account per user. Keep credentials secure.")
                bulletPoint("Household owners may invite or remove members.")
                bulletPoint("Deleting your account removes you from all households and wipes your data from our production database within 30 days.")
            }
            
            // Section 4: Points, Badges & Leaderboards
            sectionHeader("4. Points, Badges & Leaderboards")
            
            Text("Points and badges are for entertainment only – they have **no monetary value**. We may adjust or reset scores to maintain system integrity.")
                .font(Theme.Typography.bodyFontSystem)
            
            // Section 5: Acceptable Use
            sectionHeader("5. Acceptable Use")
            
            Text("You agree not to:")
                .font(Theme.Typography.bodyFontSystem)
                .padding(.bottom, 8)
                
            VStack(alignment: .leading, spacing: 12) {
                bulletPoint("Upload unlawful, hateful, or infringing content.")
                bulletPoint("Reverse‑engineer, decompile, or abuse the Service or its APIs.")
                bulletPoint("Attempt unauthorized access to other households.")
            }
            
            // Sections 6-14
            sectionHeader("6. Intellectual Property")
            
            Text("All app code, design assets, and trademarks are owned by **Debasish Chowdhury (sole proprietor)** or its licensors. You retain ownership of content you submit but grant us a worldwide, royalty‑free licence to operate the Service.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("7. Third‑Party Services")
            
            Text("The Service relies on Firebase and Apple frameworks. We are not responsible for outages or data loss caused by third‑party platforms.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("8. Disclaimer")
            
            Text("The Service is provided **\"AS IS\"** without warranties of any kind. To the maximum extent permitted by law, we disclaim implied warranties of merchantability, fitness, and non‑infringement.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("9. Limitation of Liability")
            
            Text("To the extent allowed by law, **Debasish Chowdhury (sole proprietor)** shall not be liable for indirect, incidental, consequential or punitive damages, or any loss of data, revenue, or profits.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("10. Indemnification")
            
            Text("You agree to defend and indemnify us from any claims arising out of your breach of these Terms or misuse of the Service.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("11. Termination")
            
            Text("We may suspend or terminate your account if you violate these Terms. You may stop using the Service at any time.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("12. Governing Law")
            
            Text("These Terms are governed by the laws of **Ontario, Canada**, without regard to conflict‑of‑law principles. Courts of Toronto have exclusive jurisdiction.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("13. Changes to Terms")
            
            Text("We may modify Terms at any time. Continued use after update constitutes acceptance.")
                .font(Theme.Typography.bodyFontSystem)
            
            sectionHeader("14. Contact")
            
            Text("**Debasish Chowdhury (sole proprietor)**\n**21 Ice Boat Terrace, Toronto, ON M5V 4A9, Canada**\nEmail: **support@mychore.app**")
                .font(Theme.Typography.bodyFontSystem)
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.subheadingFontSystem.bold())
            .foregroundColor(Theme.Colors.primary)
            .padding(.top, 8)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(Theme.Typography.bodyFontSystem)
            
            Text(text)
                .font(Theme.Typography.bodyFontSystem)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var legalBasesTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Purpose")
                    .font(Theme.Typography.captionFontSystem.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Theme.Colors.primary.opacity(0.1))
                
                Text("Legal Basis")
                    .font(Theme.Typography.captionFontSystem.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Theme.Colors.primary.opacity(0.1))
            }
            
            // Data rows
            tableRow(
                purpose: "Account creation & app functionality",
                basis: "Contract – Art. 6 (1)(b)"
            )
            
            tableRow(
                purpose: "Analytics & crash reporting",
                basis: "Legitimate interest – Art. 6 (1)(f)",
                isAlternate: true
            )
            
            tableRow(
                purpose: "Optional marketing emails (if ever)",
                basis: "Consent – Art. 6 (1)(a)"
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(Theme.Dimensions.cornerRadiusSmall)
    }
    
    private func tableRow(purpose: String, basis: String, isAlternate: Bool = false) -> some View {
        HStack {
            Text(purpose)
                .font(Theme.Typography.captionFontSystem)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isAlternate ? Color.gray.opacity(0.05) : Color.clear)
            
            Text(basis)
                .font(Theme.Typography.captionFontSystem)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isAlternate ? Color.gray.opacity(0.05) : Color.clear)
        }
    }
}

/// View modifier that creates a card-like container for content
struct CardViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardViewModifier())
    }
}

struct PrivacyTermsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyTermsView()
    }
}
