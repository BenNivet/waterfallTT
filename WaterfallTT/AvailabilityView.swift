//
//  AvailabilityView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 09/07/2025.
//

import FirebaseAnalytics
import SwiftUI

struct AvailabilityView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var sensorFeedback = false

    private let firestoreManager = FirestoreManager.shared

    private var players: [Player] {
        dataManager.players
    }

    private var totalPlayers: (Int, Int) {
        let availablePlayersCount = players.filter(\.isAvailable).count
        let totalPlayersCount = players.count
        return (availablePlayersCount, totalPlayersCount)
    }

    var body: some View {
        NavigationStack {
            mainView
                .addLinearGradientBackground()
                .navigationTitle("Joueurs \(totalPlayers.0)/\(totalPlayers.1)")
                .sensoryFeedback(.success, trigger: sensorFeedback)
        }
    }

    @ViewBuilder private var mainView: some View {
        ScrollView {
            if players.isEmpty {
                VStack {
                    Spacer()
                    Text("Aucun joueur")
                        .font(.title)
                        .padding(.horizontal, CharterConstants.marginLarge)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                playersView
            }
        }
        .scrollIndicators(.hidden)
    }

    private var playersView: some View {
        WrappingHStack(alignment: .leading,
                       horizontalSpacing: CharterConstants.marginXSmall,
                       verticalSpacing: CharterConstants.marginXSmall) {
            ForEach(players.sorted { $0.points > $1.points }) { player in
                Chip(model: ChipModel(isActive: isAvailable(player),
                                      title: "\(player.name) (\(player.points))"),
                     sizeFont: 12)
            }
        }
        .padding(.horizontal, CharterConstants.marginXSmall)
        .padding(.vertical, CharterConstants.margin)
    }

    private func isAvailable(_ player: Player) -> Binding<Bool> {
        Binding {
            player.isAvailable
        } set: { _ in
            if entitlementManager.canUpdate {
                toggleAvailability(of: player)
                sensorFeedback.toggle()
            }
        }
    }

    private func toggleAvailability(of player: Player) {
        if let index = players.firstIndex(of: player) {
            var player = players[index]
            player.teamId.removeAll()
            player.isCaptain = false
            player.isAvailable.toggle()
            firestoreManager.updatePlayer(player)
            dataManager.players[index] = player
            Analytics.logEvent(LogEvent.updateAvailabilityPlayer, parameters: nil)
        }
    }
}
