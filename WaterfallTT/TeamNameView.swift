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

    @State private var newName = ""

    let team: Team
    private let firestoreManager = FirestoreManager.shared
    private var teams: [Team] {
        dataManager.teams
    }

    init(team: Team) {
        self.team = team
        _newName = State(initialValue: team.division)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.marginSmall) {
            FloatingTextField(placeHolder: String(localized: "Division de l'équipe"), text: $newName, isRequired: true)
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
            firestoreManager.updateTeam(newTeam)
            dataManager.teams[index] = newTeam
        }
        dismiss()
    }
}
