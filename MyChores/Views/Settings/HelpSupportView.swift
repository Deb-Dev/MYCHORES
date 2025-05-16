// HelpSupportView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI
import Foundation

/// Help and support view
struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFAQ = false
    @State private var selectedQuestion: FAQItem?
    @State private var feedbackText = ""
    @State private var showingFeedbackSent = false
    
    // Sample FAQ items
    private let faqItems = [
        FAQItem(
            question: "How do I create a new chore?",
            answer: "To create a new chore, tap the + button at the top right of the Chores tab. Fill in the details like title, description, due date, and assigned person. Tap Save to create the chore."
        ),
        FAQItem(
            question: "How do points work?",
            answer: "Each chore has a point value associated with it. When you complete a chore, you earn those points. Points are tracked weekly and monthly on the leaderboard. Higher point values typically indicate more complex or time-consuming chores."
        ),
        FAQItem(
            question: "How do I invite others to my household?",
            answer: "In the Household tab, tap 'Invite Member' and share the generated invitation code with others. They can enter this code when joining a household to become members of your group."
        ),
        FAQItem(
            question: "How do badges work?",
            answer: "Badges are earned by completing achievements, such as completing a certain number of chores or maintaining a streak. You can view your earned badges in the Achievements tab."
        ),
        FAQItem(
            question: "Can I edit or delete a chore?",
            answer: "Yes! Tap on a chore to view its details. From there, you can tap the Edit button to modify it or the trash icon to delete it. Only the creator or the assignee can edit or delete a chore."
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                List {
                    Section {
                        ForEach(faqItems) { item in
                            Button {
                                selectedQuestion = item
                                showingFAQ = true
                            } label: {
                                HStack {
                                    Text(item.question)
                                        .foregroundColor(Theme.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .font(.caption)
                                }
                            }
                        }
                    } header: {
                        Text("Frequently Asked Questions")
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Send us Feedback")
                                .font(Theme.Typography.bodyFontSystem)
                                .foregroundColor(Theme.Colors.text)
                            
                            TextEditor(text: $feedbackText)
                                .frame(minHeight: 120)
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                                .padding(2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                        .stroke(Theme.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                sendFeedback()
                            } label: {
                                Text("Submit Feedback")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(feedbackText.isEmpty ? Theme.Colors.primary.opacity(0.6) : Theme.Colors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            }
                            .disabled(feedbackText.isEmpty)
                        }
                    } header: {
                        Text("Contact Support")
                    } footer: {
                        Text("We'll respond to your feedback as soon as possible.")
                    }
                }
                .navigationTitle("Help & Support")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingFAQ) {
                    if let question = selectedQuestion {
                        faqDetailView(faq: question)
                    }
                }
                .alert("Feedback Sent", isPresented: $showingFeedbackSent) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Thank you for your feedback! We'll review it as soon as possible.")
                }
            }
        }
    }
    
    private func faqDetailView(faq: FAQItem) -> some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(faq.question)
                            .font(Theme.Typography.headingFontSystem)
                            .foregroundColor(Theme.Colors.text)
                            .padding(.bottom, 8)
                        
                        Text(faq.answer)
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.text)
                            .lineSpacing(4)
                    }
                    .padding()
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingFAQ = false
                    }
                }
            }
        }
    }
    
    private func sendFeedback() {
        // Here we would send the feedback to the support team
        // For now, we'll just show a success alert
        feedbackText = ""
        showingFeedbackSent = true
    }
}

// Helper types
struct FAQItem: Identifiable {
    var id = UUID()
    let question: String
    let answer: String
}

#Preview {
    HelpSupportView()
}
