//
//  TeamSnapshotView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import SwiftUI

struct TeamSnapshotView: View {
    @EnvironmentObject private var dataManager: DataManager

    let teams: [Team]
    let players: [Player]
    
    init(teams: [Team], players: [Player]) {
        self.teams = teams
        self.players = players
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CharterConstants.margin) {
            Text("Répartition des équipes")
                .font(.title)
                .bold()

            ForEach(teams) { team in
                VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
                    Text(teamName(team))
                        .font(.headline)
                    players(in: team)
                }
                .padding(.bottom, CharterConstants.marginSmall)
            }
        }
        .padding()
        .background(Color.white)
    }

    func players(in team: Team) -> some View {
        ForEach(players
            .filter { $0.teamId == team.teamId }
            .sorted { $0.points > $1.points }
            .sorted { $0.isCaptain && !$1.isCaptain },
                id: \.id) { player in
            Text("• \(player.name)" + (player.isCaptain ? " (C)" : ""))
        }
    }
    
    private func teamName(_ team: Team) -> String {
        var name = team.name
        if !team.division.isEmpty {
            name += " - \(team.division)"
        }
        if !team.location.isEmpty {
            name += " (\(team.location))"
        } else {
            name += " (Domicile)"
        }
        return name
    }
}
