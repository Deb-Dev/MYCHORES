// TermsAcceptanceView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// View for accepting terms and conditions during onboarding
struct TermsAcceptanceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var termsAccepted = false
    @State private var privacyAccepted = false
    @State private var showingPrivacyTerms = false
    @State private var privacyTermsInitialTab = 0
    @State private var isLoading = false
    
    var onAccepted: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Before You Start")
                        .font(Theme.Typography.titleFontSystem)
                        .foregroundStyle(Theme.Colors.text)
                        .padding(.top, 16)
                    
                    Text("Please review and accept our terms and privacy policy.")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    
                    // Terms and Privacy checkboxes
                    VStack(alignment: .leading, spacing: 20) {
                        // Terms of Service
                        HStack(alignment: .top) {
                            Button {
                                termsAccepted.toggle()
                            } label: {
                                Image(systemName: termsAccepted ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(termsAccepted ? Theme.Colors.primary : Theme.Colors.textSecondary)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the Terms of Service")
                                    .font(Theme.Typography.bodyFontSystem)
                                    .foregroundStyle(Theme.Colors.text)
                                
                                Button {
                                    privacyTermsInitialTab = 1 // Terms tab
                                    showingPrivacyTerms = true
                                } label: {
                                    Text("Read Terms of Service")
                                        .font(Theme.Typography.captionFontSystem.bold())
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                            }
                        }
                        
                        // Privacy Policy
                        HStack(alignment: .top) {
                            Button {
                                privacyAccepted.toggle()
                            } label: {
                                Image(systemName: privacyAccepted ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(privacyAccepted ? Theme.Colors.primary : Theme.Colors.textSecondary)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the Privacy Policy")
                                    .font(Theme.Typography.bodyFontSystem)
                                    .foregroundStyle(Theme.Colors.text)
                                
                                Button {
                                    privacyTermsInitialTab = 0 // Privacy tab
                                    showingPrivacyTerms = true
                                } label: {
                                    Text("Read Privacy Policy")
                                        .font(Theme.Typography.captionFontSystem.bold())
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    
                    // Information text
                    Text("You must accept both the Terms of Service and Privacy Policy to use MyChores.")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Continue button
                    Button {
                        completeTermsAcceptance()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical)
                        } else {
                            Text("Continue")
                                .font(Theme.Typography.bodyFontSystem.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical)
                        }
                    }
                    .background(canContinue ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.5))
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .disabled(!canContinue || isLoading)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingPrivacyTerms) {
                PrivacyTermsViewWithTab(initialTab: privacyTermsInitialTab)
            }
        }
    }
    
    private var canContinue: Bool {
        termsAccepted && privacyAccepted
    }
    
    private func completeTermsAcceptance() {
        guard canContinue else { return }
        
        isLoading = true
        
        // Store acceptance in UserDefaults and Firestore
        UserDefaults.standard.set(true, forKey: "termsAccepted")
        UserDefaults.standard.set(true, forKey: "privacyAccepted")
        UserDefaults.standard.set(Date(), forKey: "termsAcceptanceDate")
        
        // Update user record in Firestore
        Task {
            await authViewModel.updateUserTermsAcceptance(
                termsAccepted: true,
                privacyAccepted: true,
                acceptanceDate: Date()
            )
            
            // Call the completion handler
            DispatchQueue.main.async {
                isLoading = false
                onAccepted()
            }
        }
    }
}

#Preview {
    TermsAcceptanceView(onAccepted: {})
        .environmentObject(AuthViewModel())
}
