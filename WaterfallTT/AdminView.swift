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
        guard !searchText.isEmpty else { return clubs }
        let queryFormatted = searchText.queryFormatted
        return clubs.filter { $0.name.queryFormatted.contains(queryFormatted) }
    }

    var body: some View {
        NavigationStack {
            mainView
                .task {
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
            VStack(spacing: 0) {
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
        .searchable(text: $searchText)
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
                    Text(club.date)
                        .font(.footnote)
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
