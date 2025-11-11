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
    private let firestoreManager = FirestoreManager.shared

    var body: some View {
        NavigationStack {
            mainView
                .task {
                    clubs = await firestoreManager.fetchAllUsers()
                    players = await firestoreManager.fetchAllPlayers()
                }
                .addLinearGradientBackground()
                .navigationTitle("Admin")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var mainView: some View {
        ScrollView {
            HStack {
                Spacer()
                Text("\(clubs.count) clubs")
                    .font(.headline)
                Spacer()
            }
            VStack(spacing: 0) {
                ForEach(clubs, id: \.documentId) { club in
                    clubView(for: club)
                }
            }
            .background(RoundedRectangle(cornerRadius: CharterConstants.radius)
                .stroke(CharterConstants.halfGray, lineWidth: 1))
            .padding(CharterConstants.margin)
        }
        .scrollIndicators(.hidden)
    }

    private func clubView(for club: User) -> some View {
        Button {
            if let url = URL(string: "waterfalltt://code/\(club.documentId)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: CharterConstants.marginSmall) {
                Text(club.name.isEmpty ? "Nom inconnu" : club.name)
                    .padding(.vertical, CharterConstants.margin)
                Spacer()
                players(for: club)
            }
            .padding(.horizontal, CharterConstants.margin)
            .font(.headline)
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
            let playerInTeam = players.filter { !$0.teamId.isEmpty }.count
            let string = "\(playerInTeam)/\(players.count)"
            Text(string)
                .padding(CharterConstants.marginSmall)
                .font(.subheadline)
                .background(CharterConstants.mainColor)
                .clipShape(Capsule())
        }
    }
}
