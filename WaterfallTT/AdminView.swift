//
//  AdminView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 09/10/2025.
//

import SwiftUI

struct AdminView: View {
    @State private var clubs: [User] = []
    @State private var players: [Player] = []
    @State private var searchText = ""

    private let firestoreManager = FirestoreManager.shared
    private var filteredClubs: [User] {
        let queryFormatted = searchText.queryFormatted
        let filteredClubs: [User] = searchText.isEmpty
            ? clubs
            : clubs.filter { $0.name.queryFormatted.contains(queryFormatted) }

        let latestUpdates: [String: Date] = Dictionary(grouping: players, by: \.userId)
            .compactMapValues { $0.compactMap(\.lastUpdate).max() }

        return filteredClubs.sorted { (lhs: User, rhs: User) in
            let lhsLatestUpdate = latestUpdates[lhs.documentId]
            let rhsLatestUpdate = latestUpdates[rhs.documentId]
            let lhsCreation = Helper.shared.date(from: lhs.date) ?? .distantPast
            let rhsCreation = Helper.shared.date(from: rhs.date) ?? .distantPast
            let lhsDate = lhsLatestUpdate ?? lhsCreation
            let rhsDate = rhsLatestUpdate ?? rhsCreation

            return if lhsDate == rhsDate {
                if lhsLatestUpdate == rhsLatestUpdate {
                    rhsCreation > lhsCreation
                } else {
                    lhsLatestUpdate != nil && rhsLatestUpdate == nil
                }
            } else {
                lhsDate > rhsDate
            }
        }
    }

    var body: some View {
        NavigationStack {
            mainView
                .task {
                    guard clubs.isEmpty else { return }
                    clubs = await firestoreManager.fetchAllUsers()
                    players = await firestoreManager.fetchAllPlayers()
                }
                .addLinearGradientBackground()
                .navigationTitle("Admin" + (clubs.isEmpty ? "" : " (\(clubs.count) clubs)"))
//                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var mainView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredClubs, id: \.documentId) { club in
                    clubView(for: club)
                }
            }
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: CharterConstants.radius)
                .stroke(CharterConstants.halfGray, lineWidth: 1))
            .padding(CharterConstants.margin)
        }
        .scrollIndicators(.hidden)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Rechercher")
    }

    private func clubView(for club: User) -> some View {
        Button {
            if let url = URL(string: "waterfalltt://code/\(club.documentId)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: CharterConstants.marginSmall) {
                VStack(alignment: .leading) {
                    Text(club.name.isEmpty ? "Inconnu" : club.name.trimmingCharacters(in: .whitespaces))
                        .font(.headline)
                    HStack(spacing: CharterConstants.marginSmall) {
                        if let latestUpdate = latestUpdate(for: club),
                           club.date != Helper.shared.string(from: latestUpdate) {
                            Label(Helper.shared.updateString(from: latestUpdate), systemImage: "clock")
                                .font(.footnote)
                        }
                        Label(club.date, systemImage: "calendar")
                            .font(.caption)
                    }
                }
                Spacer()
                players(for: club)
            }
            .padding(.horizontal, CharterConstants.margin)
            .padding(.vertical, CharterConstants.marginSmall)
            .contentShape(Rectangle())
        }
        .overlay(alignment: .bottom) {
            Divider()
                .frame(height: 0.5)
                .background(CharterConstants.halfGray)
        }
        .buttonStyle(.plain)
    }

    private func latestUpdate(for club: User) -> Date? {
        players
            .filter { $0.userId == club.documentId }
            .compactMap(\.lastUpdate)
            .max()
    }

    @ViewBuilder
    private func players(for club: User) -> some View {
        let players = players.filter { $0.userId == club.documentId }
        if !players.isEmpty {
            let playerInTeam = players.count(where: { !$0.teamId.isEmpty })
            let string = "\(playerInTeam)/\(players.count)"
            Text(string)
                .padding(CharterConstants.marginSmall)
                .font(.subheadline)
                .background(CharterConstants.mainColor)
                .clipShape(Capsule())
        }
    }
}
