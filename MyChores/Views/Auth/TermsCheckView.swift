// TermsCheckView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// View for checking and handling terms acceptance after login
struct TermsCheckView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingTermsAcceptance = false
    @State private var hasCheckedTerms = false
    
    var body: some View {
        ZStack {
            // This view itself is essentially invisible - it acts as a terms acceptance router
            // If terms haven't been accepted, show TermsAcceptanceView sheet
            Color.clear
                .onAppear {
                    checkTermsAcceptance()
                }
                .sheet(isPresented: $showingTermsAcceptance) {
                    TermsAcceptanceView(onAccepted: {
                        showingTermsAcceptance = false
                    })
                }
        }
    }
    
    private func checkTermsAcceptance() {
        // Avoid checking multiple times
        guard !hasCheckedTerms else { return }
        hasCheckedTerms = true
        
        // If the user hasn't accepted terms and privacy, show the terms acceptance view
        if !authViewModel.hasAcceptedTerms {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingTermsAcceptance = true
            }
        }
    }
}

#Preview {
    TermsCheckView()
        .environmentObject(AuthViewModel())
}
