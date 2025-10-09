//
//  SelectPlayerView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 09/07/2025.
//

import FirebaseAnalytics
import SwiftUI

struct SelectPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var selectedPlayers: [Player]

    private let firestoreManager = FirestoreManager.shared

    private let teamIndex: Int

    private var players: [Player] {
        dataManager.players
    }

    private var teams: [Team] {
        dataManager.teams
    }

    private var availablePlayers: [Player] {
        players
            .filter { $0.isAvailable && $0.teamId.isEmpty }
            .sorted { $0.points > $1.points }
    }

    init(teamIndex: Int, selectedPlayers: [Player]) {
        self.teamIndex = teamIndex
        _selectedPlayers = State(initialValue: selectedPlayers)
    }

    private func selectedPlayersBinding(player: Player) -> Binding<Bool> {
        Binding {
            selectedPlayers.contains(player)
        } set: { _ in
            if let index = selectedPlayers.firstIndex(where: { $0 == player }) {
                selectedPlayers.remove(at: index)
            } else {
                selectedPlayers.append(player)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: CharterConstants.margin) {
                ScrollView {
                    playersView
                        .padding(.horizontal, CharterConstants.marginXSmall)
                        .padding(.vertical, CharterConstants.margin)
                }
                Button("Valider") {
                    save()
                }
                .padding(.horizontal, CharterConstants.margin)
                .buttonStyle(PrimaryButtonStyle())
            }
            .addLinearGradientBackground()
            .scrollIndicators(.hidden)
            .navigationTitle("Sélection des joueurs")
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

    @ViewBuilder private var playersView: some View {
        if availablePlayers.isEmpty {
            Text("Aucun joueur disponible")
                .font(.title2)
        } else {
            WrappingHStack(alignment: .leading,
                           horizontalSpacing: CharterConstants.marginXSmall,
                           verticalSpacing: CharterConstants.marginXSmall) {
                ForEach(availablePlayers) { player in
                    Chip(model: ChipModel(isActive: selectedPlayersBinding(player: player),
                                          title: "\(player.name) (\(player.points))"),
                         sizeFont: 12)
                }
            }
        }
    }

    private func save() {
        if !selectedPlayers.isEmpty {
            var indexMaxPoint: Int?
            for i in players.indices {
                var player = players[i]
                if selectedPlayers.contains(player) {
                    player.teamId = teams[teamIndex].teamId
                    firestoreManager.updatePlayer(player)
                    dataManager.players[i] = player
                    if indexMaxPoint == nil
                        || players[i].points > players[indexMaxPoint ?? i].points {
                        indexMaxPoint = i
                    }
                }
            }
            if let indexMaxPoint,
               selectedPlayers.allSatisfy({ !$0.isCaptain }) {
                var maxPlayer = players[indexMaxPoint]
                maxPlayer.isCaptain = true
                firestoreManager.updatePlayer(maxPlayer)
                dataManager.players[indexMaxPoint] = maxPlayer
            }
            Analytics.logEvent(LogEvent.updateTeam, parameters: nil)
        }
        dismiss()
    }
}
