//
//  ClubListView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 01/10/2025.
//

import SwiftUI

public struct ClubListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var clubId: String
    @State private var clubs: [User] = []
    @State private var showingNameAlert = false
    @State private var nameText = ""

    private let firestoreManager = FirestoreManager.shared

    var clubsList: [UserStore] {
        entitlementManager.usersStored
    }

    init(clubId: String) {
        _clubId = State(initialValue: clubId)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.margin) {
            ScrollView {
                clubsView
                    .task {
                        if !clubsList.isEmpty {
                            var allClubs = await firestoreManager.fetchUsers(for: clubsList.map(\.userId))
                            if let selectedClubIndex = allClubs.firstIndex(where: { $0.documentId == clubId }) {
                                let selectedClub = allClubs.remove(at: selectedClubIndex)
                                allClubs.insert(selectedClub, at: 0)
                            }
                            clubs = allClubs
                        }
                    }
            }
            .scrollIndicators(.hidden)

            Spacer()
            Button("Fermer") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    var clubsView: some View {
        VStack(spacing: 0) {
            ForEach(clubs, id: \.documentId) { club in
                clubView(for: club)
            }
            addNewClubButtonView
        }
        .background(RoundedRectangle(cornerRadius: CharterConstants.radius)
            .stroke(CharterConstants.halfGray, lineWidth: 1))
        .padding(CharterConstants.margin)
    }

    private func clubView(for club: User) -> some View {
        Button {
            let canUpdate = clubsList.first(where: { $0.userId == club.documentId })?.canUpdate ?? false
            if let url = URL(string: "waterfalltt://code/\(club.documentId)\(canUpdate ? "" : "-0")") {
                UIApplication.shared.open(url)
            }
            dismiss()
        } label: {
            HStack {
                Text(club.name.isEmpty ? "Nom inconnu" : club.name)
                    .font(.headline)
                Spacer()
                if club.documentId == clubId {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: CharterConstants.margin, height: CharterConstants.margin)
                        .foregroundStyle(.white)
                }
            }
            .padding(CharterConstants.marginMedium)
            .contentShape(Rectangle())
        }
        .overlay(alignment: .bottom) {
            Divider()
                .frame(height: 0.5)
                .background(CharterConstants.halfGray)
        }
        .buttonStyle(.plain)
    }

    private var addNewClubButtonView: some View {
        Button {
            showingNameAlert = true
        } label: {
            HStack(spacing: CharterConstants.margin) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: CharterConstants.marginLarge, height: CharterConstants.marginLarge)
                Text("Créer un nouveau club")
                    .font(.headline)
                Spacer()
            }
            .padding(CharterConstants.margin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .alert("Créer un nouveau club", isPresented: $showingNameAlert) {
            TextField("Nom", text: $nameText)
                .autocorrectionDisabled()
            Button("Annuler", role: .cancel) {}
            Button("OK") {
                if !nameText.isEmpty {
                    Task {
                        if let user = await firestoreManager.createUser(name: nameText),
                           let url = URL(string: "waterfalltt://code/\(user.documentId)") {
                            await UIApplication.shared.open(url)
                        }
                        dismiss()
                    }
                }
            }
            .disabled(nameText.isEmpty)
        } message: {
            Text("Veuillez entrer le nom du club")
        }
    }
}
