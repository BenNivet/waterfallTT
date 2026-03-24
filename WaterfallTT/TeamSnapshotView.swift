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
    var numberOfArray: Int {
        guard teams.count > 3 else { return teams.count }
        return Int(ceil(Double(teams.count) / 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CharterConstants.margin) {
            Text("Compositions")
                .font(.title)
                .bold()

            ForEach(teams.splitInSubArrays(into: numberOfArray), id: \.self) { array in
                HStack(alignment: .top, spacing: CharterConstants.margin) {
                    ForEach(array) { team in
                        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
                            Text(teamName(team))
                                .font(.headline)
                            locationView(team)
                            players(in: team)
                        }
                    }
                }
                .padding(.bottom, CharterConstants.marginSmall)
            }
        }
        .padding(CharterConstants.margin)
        .background(Color.white)
    }

    func players(in team: Team) -> some View {
        ForEach(players
            .filter { $0.teamId == team.teamId }
            .sorted { $0.points > $1.points }
            .sorted { $0.isCaptain && !$1.isCaptain },
            id: \.id) { player in
                Text("• \(player.name)"
                    + " (\(player.points))"
                    + (player.isCaptain ? " (C)" : ""))
            }
    }

    private func teamName(_ team: Team) -> String {
        var name = team.name
        if !team.division.isEmpty {
            name += " - \(team.division)"
        }
        return name
    }

    private func locationView(_ team: Team) -> some View {
        HStack(spacing: CharterConstants.marginSmall) {
            team.location.isEmpty
                ? Image(systemName: "house.fill")
                : Image(systemName: "car.fill")
            team.location.isEmpty
                ? Text("Domicile")
                : Text(team.location)
        }
        .font(.headline)
    }
}

extension Array {
    func splitInSubArrays(into size: Int) -> [[Element]] {
        var output: [[Element]] = []
        (0 ..< size).forEach {
            var subArray: [Element] = []
            for elem in stride(from: $0, to: count, by: size) {
                subArray.append(self[elem])
            }
            output.append(subArray)
        }
        return output
    }
}
