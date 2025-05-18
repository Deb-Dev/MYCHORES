// HouseholdRulesView.swift
// MyChores
//
// Created on 2025-05-18.
//

import SwiftUI

struct HouseholdRulesView: View {
    @ObservedObject var viewModel: HouseholdViewModel
    @State private var newRuleText: String = ""
    @State private var showingAddRuleAlert = false
    @State private var ruleToEdit: HouseholdRule? = nil
    @State private var editText: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Household Rules")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            if viewModel.isLoading && viewModel.householdRules.isEmpty {
                ProgressView("Loading rules...")
            } else if viewModel.householdRules.isEmpty {
                Text("No household rules defined yet. Add one below!")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                List {
                    ForEach(viewModel.householdRules) { rule in
                        HStack {
                            Text(rule.ruleText)
                            Spacer()
                            // Add edit/delete options here if desired, e.g., contextMenu
                        }
                        .contextMenu {
                            Button {
                                self.ruleToEdit = rule
                                self.editText = rule.ruleText
                            } label: {
                                Label("Edit Rule", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                viewModel.deleteHouseholdRule(rule: rule)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteRule) // Alternative swipe to delete
                }
                .listStyle(PlainListStyle())
                .frame(minHeight: CGFloat(viewModel.householdRules.count * 44)) // Adjust height dynamically
            }

            HStack {
                TextField("Enter new rule...", text: $newRuleText, onCommit: addRule)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: addRule) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.green)
                }
                .disabled(newRuleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .sheet(item: $ruleToEdit) { rule in
            EditRuleView(viewModel: viewModel, rule: rule, currentText: rule.ruleText)
        }
        .onAppear {
            if viewModel.selectedHousehold != nil && viewModel.householdRules.isEmpty {
                viewModel.loadHouseholdRules()
            }
        }
    }

    private func addRule() {
        let trimmedText = newRuleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            viewModel.addHouseholdRule(ruleText: trimmedText)
            newRuleText = ""
        }
    }
    
    private func deleteRule(at offsets: IndexSet) {
        offsets.forEach { index in
            let rule = viewModel.householdRules[index]
            viewModel.deleteHouseholdRule(rule: rule)
        }
    }
}

struct EditRuleView: View {
    @ObservedObject var viewModel: HouseholdViewModel
    let rule: HouseholdRule
    @State var currentText: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $currentText)
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.5))
                    .padding()
                
                Button("Save Changes") {
                    if !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.updateHouseholdRule(rule: rule, newText: currentText)
                        dismiss()
                    }
                }
                .padding()
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .navigationTitle("Edit Rule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview
struct HouseholdRulesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = HouseholdViewModel()
        // Mock data for preview
        let sampleHousehold = Household(id: "sampleHid", name: "Preview Household", ownerUserId: "owner", memberUserIds: ["owner", "member1"], inviteCode: "PREVIEW", createdAt: Date())
        viewModel.selectedHousehold = sampleHousehold
        viewModel.householdRules = [
            HouseholdRule(id: "1", householdId: "sampleHid", ruleText: "Keep kitchen clean.", createdByUserId: "owner", createdAt: Date()),
            HouseholdRule(id: "2", householdId: "sampleHid", ruleText: "No loud music after 10 PM.", createdByUserId: "owner", createdAt: Date(), displayOrder: 1),
            HouseholdRule(id: "3", householdId: "sampleHid", ruleText: "Take out trash on Tuesdays.", createdByUserId: "owner", createdAt: Date(), displayOrder: 0)
        ]
        viewModel.currentUser = User(id: "owner", name: "Preview User", email: "user@example.com")
        
        return HouseholdRulesView(viewModel: viewModel)
    }
}
