//
//  ExportTeamsView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 10/07/2025.
//

import SwiftUI

struct ExportTeamsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @Binding var teamsToExportBinding: [Team]

    @State private var teamsToExport: [Team] = []

    private var teams: [Team] {
        dataManager.teams
    }

    private var allTeamsBinding: Binding<Bool> {
        Binding {
            teamsToExport.count == teams.count
        } set: { newValue in
            if newValue {
                teamsToExport = teams
            } else {
                teamsToExport.removeAll()
            }
        }
    }

    init(teamsToExportBinding: Binding<[Team]>) {
        _teamsToExportBinding = teamsToExportBinding
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: CharterConstants.margin) {
                ScrollView {
                    VStack(spacing: CharterConstants.margin) {
                        Toggle(allTeamsBinding.wrappedValue ? "Tout désélectionner" : "Tout sélectionner",
                               isOn: allTeamsBinding)
                            .padding(.bottom, CharterConstants.margin)
                            .font(.headline)
                        teamsView
                    }
                    .padding(CharterConstants.margin)
                }
                Button("Valider") {
                    teamsToExportBinding = teamsToExport
                    dismiss()
                }
                .padding(.horizontal, CharterConstants.margin)
                .buttonStyle(PrimaryButtonStyle())
            }
            .keyboardAvoiding()
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                teamsToExport = teams
            }
            .addLinearGradientBackground()
            .scrollIndicators(.hidden)
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        closeButtonView
                    }
                }
            }
        }
    }

    private var teamsView: some View {
        ForEach(teams.sorted { $1.order > $0.order }) { team in
            Toggle(teamName(for: team), isOn: exportTeamsBinding(for: team))
        }
    }

    private func teamName(for team: Team) -> String {
        team.name + (team.division.isEmpty ? "" : " - \(team.division)")
    }

    private func exportTeamsBinding(for team: Team) -> Binding<Bool> {
        Binding {
            teamsToExport.contains(team)
        } set: { _ in
            if let teamIndex = teamsToExport.firstIndex(of: team) {
                teamsToExport.remove(at: teamIndex)
            } else {
                teamsToExport.append(team)
            }
        }
    }
}
