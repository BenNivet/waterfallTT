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
        VStack(spacing: CharterConstants.marginSmall) {
            FloatingTextField(placeHolder: String(localized: "Nom du joueur"), text: $newName, isRequired: true)
                .autocorrectionDisabled()
            FloatingTextField(placeHolder: String(localized: "Classement"), text: $newPoints, isRequired: true)
                .keyboardType(.numberPad)
            Spacer()
            Button("Ajouter") {
                hideKeyboard()
                Task {
                    await addNewPlayer()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(newName.isEmpty || newPoints.isEmpty)
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
        } else {
            let resultId = await firestoreManager.createUser()
            if let resultId {
                entitlementManager.userId = resultId
                player.userId = resultId
            }
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
        dismiss()
    }
}
