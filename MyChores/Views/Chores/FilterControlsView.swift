// FilterControlsView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Filter controls component for the ChoresView
struct FilterControlsView: View {
    @ObservedObject var viewModel: ChoreViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChoreViewModel.FilterMode.allCases) { mode in
                    Button {
                        viewModel.filterMode = mode
                    } label: {
                        Text(mode.rawValue)
                            .font(Theme.Typography.captionFontSystem)
                            .fontWeight(viewModel.filterMode == mode ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.filterMode == mode ?
                                    Theme.Colors.primary :
                                    Theme.Colors.systemFill
                            )
                            .foregroundColor(
                                viewModel.filterMode == mode ?
                                    .white :
                                    Theme.Colors.label
                            )
                            .cornerRadius(20)
                            .animation(.spring(), value: viewModel.filterMode)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(Theme.Colors.systemBackground)
    }
}
