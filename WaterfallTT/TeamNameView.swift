//
//  TeamNameView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 14/07/2025.
//

import SwiftUI

public struct TeamNameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var newName: String
    @State private var atHome: Bool
    @State private var location: String

    let team: Team
    private let firestoreManager = FirestoreManager.shared
    private var teams: [Team] {
        dataManager.teams
    }

    init(team: Team) {
        self.team = team
        _newName = State(initialValue: team.division)
        _atHome = State(initialValue: team.atHome)
        _location = State(initialValue: team.location)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.margin) {
            FloatingTextField(placeHolder: String(localized: "Division de l'équipe"),
                              text: $newName)
                .autocorrectionDisabled()
            Toggle("Domicile", isOn: $atHome)
            if !atHome {
                FloatingTextField(placeHolder: "Lieu de la rencontre",
                                  text: $location)
                    .autocorrectionDisabled()
            } else {
                FloatingTextField(placeHolder: "Adversaire",
                                  text: $location)
                    .autocorrectionDisabled()
            }
            Spacer()
            Button("Valider") {
                hideKeyboard()
                saveName()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(CharterConstants.margin)
        .keyboardAvoiding()
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func saveName() {
        if let index = teams.firstIndex(of: team) {
            var newTeam = teams[index]
            newTeam.division = newName
            newTeam.location = location
            newTeam.atHome = atHome
            firestoreManager.updateTeam(newTeam)
            dataManager.teams[index] = newTeam
        }
        dismiss()
    }
}
