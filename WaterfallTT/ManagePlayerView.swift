//
//  ManagePlayerView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import FirebaseAnalytics
import SwiftUI

public struct ManagePlayerView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var newName = ""
    @State private var newPoints = ""

    @Environment(\.dismiss) var dismiss

    let player: Player?
    private let firestoreManager = FirestoreManager.shared

    private var players: [Player] {
        dataManager.players
    }

    init(player: Player? = nil, newName: String = "", newPoints: String = "") {
        self.player = player
        _newName = State(initialValue: newName)
        _newPoints = State(initialValue: newPoints)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.margin) {
            FloatingTextField(placeHolder: String(localized: "Nom du joueur"), text: $newName, isRequired: true)
                .autocorrectionDisabled()
            FloatingTextField(placeHolder: String(localized: "Classement"), text: $newPoints, isRequired: true)
                .keyboardType(.numberPad)
            Spacer()
            Button(player == nil ? "Ajouter" : "Sauvegarder") {
                hideKeyboard()
                Task {
                    await addNewPlayer()
                    dismiss()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(newName.isEmpty || newPoints.isEmpty)
            if player != nil {
                Button("Supprimer") {
                    hideKeyboard()
                    deletePlayer()
                }
                .buttonStyle(DestructiveButtonStyle())
                .disabled(newName.isEmpty || newPoints.isEmpty)
            }
        }
        .padding(CharterConstants.margin)
        .keyboardAvoiding()
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func addNewPlayer() async {
        guard !newName.isEmpty, let points = Int(newPoints)
        else { return }

        if player == nil {
            Analytics.logEvent(LogEvent.addPlayer, parameters: nil)
        } else {
            Analytics.logEvent(LogEvent.updatePlayer, parameters: nil)
        }

        var player = player ?? Player(name: newName, points: points)
        player.name = newName
        player.points = points

        if let userId = entitlementManager.userId {
            player.userId = userId
        } else if let user = await firestoreManager.createUser() {
            entitlementManager.userId = user.documentId
            entitlementManager.canUpdate = true
            entitlementManager.appendUserIfNeeded(userId: user.documentId, canUpdate: true)
            dataManager.user = user
            player.userId = user.documentId
        }
        let playerId = await firestoreManager.insertOrUpdatePlayer(player)
        guard let playerId else { return }
        player.playerId = playerId
        if let index = players.firstIndex(of: player) {
            dataManager.players[index] = player
        } else {
            dataManager.players.append(player)
        }

        newName = ""
        newPoints = ""
    }

    func deletePlayer() {
        if let player,
           let playerIndex = players.firstIndex(where: { $0.id == player.id }) {
            let player = players[playerIndex]
            firestoreManager.deletePlayer(player)
            dataManager.players.remove(at: playerIndex)
        }
        dismiss()
    }
}
