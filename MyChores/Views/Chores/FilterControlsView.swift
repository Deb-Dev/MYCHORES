// FilterControlsView.swift
// MyChores
//
// Created on 2025-05-02.
// Enhanced on 2025-05-14.
//

import SwiftUI

/// Filter controls component for the ChoresView
struct FilterControlsView: View {
    @ObservedObject var viewModel: ChoreViewModel
    @State private var animateControls = false
    
    // Mapping filter modes to icons
    private func iconName(for mode: ChoreViewModel.FilterMode) -> String {
        switch mode {
        case .all:
            return "list.bullet"
        case .mine:
            return "person.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .pending:
            return "circle"
        case .overdue:
            return "exclamationmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Subtle separator line
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(ChoreViewModel.FilterMode.allCases.enumerated()), id: \.element) { index, mode in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.filterMode = mode
                            }
                        } label: {
                            HStack(spacing: 6) {
                                // Icon with background
                                Image(systemName: iconName(for: mode))
                                    .font(.system(size: 12, weight: viewModel.filterMode == mode ? .bold : .regular))
                                    .foregroundColor(viewModel.filterMode == mode ? .white : Theme.Colors.primary)
                                    .frame(width: viewModel.filterMode == mode ? 24 : 0)
                                    .opacity(viewModel.filterMode == mode ? 1 : 0)
                                
                                // Filter text
                                Text(mode.rawValue.capitalized)
                                    .font(.system(size: 14, weight: viewModel.filterMode == mode ? .semibold : .medium))
                                    .foregroundColor(
                                        viewModel.filterMode == mode ?
                                            .white :
                                            Theme.Colors.text
                                    )
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        viewModel.filterMode == mode ?
                                            Theme.Colors.primary :
                                            Color.gray.opacity(0.1)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        viewModel.filterMode == mode ?
                                            Theme.Colors.primary :
                                            Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: viewModel.filterMode == mode ?
                                    Theme.Colors.primary.opacity(0.3) : Color.clear,
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        }
                        .scaleEffect(animateControls ? 1.0 : 0.9)
                        .opacity(animateControls ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                            value: animateControls
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Theme.Colors.background)
            
            // Bottom shadow
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 4)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateControls = true
            }
        }
    }
}

#Preview {
    VStack {
        FilterControlsView(viewModel: ChoreViewModel(householdId: "sample"))
        Spacer()
    }
    .background(Theme.Colors.background)
}
