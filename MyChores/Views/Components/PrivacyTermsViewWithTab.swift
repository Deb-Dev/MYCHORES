// PrivacyTermsViewWithTab.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// Wrapper for PrivacyTermsView that allows setting the initial tab
struct PrivacyTermsViewWithTab: View {
    let initialTab: Int
    
    var body: some View {
        PrivacyTermsView(initialTab: initialTab)
    }
}
