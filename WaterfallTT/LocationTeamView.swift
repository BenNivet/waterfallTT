//
//  LocationTeamView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 10/07/2025.
//

import SwiftUI

struct LocationTeamView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var homeTeams: [Team]

    private let firestoreManager = FirestoreManager.shared

    private var teams: [Team] {
        dataManager.teams
    }
    
    init(homeTeams: [Team]) {
        _homeTeams = State(initialValue: homeTeams)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: CharterConstants.margin) {
                ScrollView {
                    VStack(spacing: CharterConstants.margin) {
                        teamsView
                    }
                    .padding(CharterConstants.margin)
                }
                Button("Valider") {
                    dismiss()
                }
                .padding(.horizontal, CharterConstants.margin)
                .buttonStyle(PrimaryButtonStyle())
            }
            .keyboardAvoiding()
            .onTapGesture {
                hideKeyboard()
            }
            .addLinearGradientBackground()
            .scrollIndicators(.hidden)
            .navigationTitle("Lieu des équipes")
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
            VStack(spacing: CharterConstants.marginSmall) {
                Text(team.name)
                Toggle("Domicile", isOn: homeTeamsBinding(for: team))
                if !homeTeams.contains(team) {
                    FloatingTextField(placeHolder: "Lieu de la rencontre",
                                      text: locationBinding(for: team))
                    .autocorrectionDisabled()
                }
            }
        }
    }

    private func homeTeamsBinding(for team: Team) -> Binding<Bool> {
        Binding {
            homeTeams.contains(team)
        } set: { _ in
            if let homeIndex = homeTeams.firstIndex(of: team) {
                homeTeams.remove(at: homeIndex)
            } else {
                homeTeams.append(team)
                if let index = teams.firstIndex(of: team) {
                    var newTeam = teams[index]
                    newTeam.location.removeAll()
                    firestoreManager.updateTeam(team)
                    dataManager.teams[index] = newTeam
                }
            }
        }
    }

    private func locationBinding(for team: Team) -> Binding<String> {
        Binding {
            team.location
        } set: { newValue in
            if let index = teams.firstIndex(of: team) {
                var newTeam = teams[index]
                newTeam.location = newValue
                firestoreManager.updateTeam(team)
                dataManager.teams[index] = newTeam
            }
        }
    }
}
