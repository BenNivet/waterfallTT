//
//  TeamSnapshotView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import SwiftUI

struct TeamSnapshotView: View {
    let teams: [Team]
    let players: [Player]
    let columnCount: Int
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: CharterConstants.margin), count: columnCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CharterConstants.margin) {
            Text("Compositions")
                .font(.title)
                .bold()

            LazyVGrid(columns: columns, alignment: .leading, spacing: CharterConstants.margin) {
                ForEach(teams) { team in
                    VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
                        Text(teamName(team))
                            .font(.headline)
                        locationView(team)
                        players(in: team)
                    }
                }
            }
        }
        .padding(CharterConstants.margin)
        .background(Color.white)
    }

    func players(in team: Team) -> some View {
        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
            ForEach(players
                .filter { $0.teamId == team.teamId }
                .sorted { $0.points > $1.points }
                .sorted { $0.isCaptain && !$1.isCaptain },
                id: \.id) { player in
                    HStack(spacing: CharterConstants.marginXSmall) {
                        Text("•")
                        Text(player.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .truncationMode(.middle)

                        Text("(\(player.points))")

                        if player.isCaptain {
                            Text("(C)")
                                .bold()
                        }
                        Spacer(minLength: CharterConstants.marginXSmall)
                    }
                }
        }
    }

    private func teamName(_ team: Team) -> String {
        "\(team.name)"
            + (team.division.isEmpty
                ? ""
                : " - \(team.division)")
                + "\n\(totalPoints(team)) pts (~\(averagePoints(team).toMinimalString))"
    }

    private func locationView(_ team: Team) -> some View {
        HStack(spacing: CharterConstants.marginSmall) {
            team.atHome
                ? Image(systemName: "house.fill")
                : Image(systemName: "car.fill")

            Text(team.formattedLocationName)
        }
        .font(.headline)
    }

    private func averagePoints(_ team: Team) -> Double {
        let players = players.filter { $0.teamId == team.teamId }
        guard !players.isEmpty else { return 0 }
        return Double(totalPoints(team)) / Double(players.count)
    }

    private func totalPoints(_ team: Team) -> Int {
        let players = players.filter { $0.teamId == team.teamId }
        return players.reduce(0) { $0 + $1.points }
    }
}
