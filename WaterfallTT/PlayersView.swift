//
//  PlayersView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import FirebaseAnalytics
import SwiftUI

struct PlayersView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var isLoaderPresented = false
    @State private var showAddPlayerView = false
    @State private var showManagePlayerView: Player?
    @State private var showDocumentPicker = false
    @State private var showInterstitialPicker = false
    @State private var searchText: String = ""
    @State private var results: [(name: String, points: Int)] = []

    private let firestoreManager = FirestoreManager.shared

    private var players: [Player] {
        dataManager.players
    }

    private var filteredPlayers: [Player] {
        guard !searchText.isEmpty
        else { return players }

        return players.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    private var displayedPlayers: [Player] {
        filteredPlayers.sorted(by: { $0.points > $1.points })
    }

    private var showManagePlayerViewBinding: Binding<Bool> {
        Binding {
            showManagePlayerView != nil
        } set: { _ in
            showManagePlayerView = nil
        }
    }

    var body: some View {
        NavigationView {
            mainView
                .padding(.vertical, CharterConstants.margin)
                .addLinearGradientBackground()
                .navigationTitle("Joueurs")
                .toolbar {
                    if entitlementManager.canUpdate {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                if entitlementManager.hasSeenImportInterstitial {
                                    showDocumentPicker = true
                                } else {
                                    showInterstitialPicker = true
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showAddPlayerView = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            EditButton()
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showInterstitialPicker = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showAddPlayerView) {
                    ManagePlayerView()
                        .presentationDetents([.fraction(0.4)])
                }
                .sheet(isPresented: showManagePlayerViewBinding) {
                    ManagePlayerView(player: showManagePlayerView,
                                     newName: showManagePlayerView?.name ?? "",
                                     newPoints: String(showManagePlayerView?.points ?? 0))
                        .presentationDetents([.fraction(0.4)])
                }
                .fullScreenCover(isPresented: $showInterstitialPicker) {
                    ImportInterstitialView(isPresented: $showInterstitialPicker)
                        .onDisappear {
                            showDocumentPicker = true
                        }
                }
                .sheet(isPresented: $showDocumentPicker) {
                    DocumentPicker { url in
                        if let url {
                            extractLines(from: url)
                        }
                    }
                }
                .loader(isPresented: $isLoaderPresented)
        }
    }

    @ViewBuilder private var mainView: some View {
        if searchText.isEmpty, displayedPlayers.isEmpty {
            VStack {
                Spacer()
                VStack(spacing: CharterConstants.margin) {
                    Text("Aucun joueur")
                        .font(.title)
                    if entitlementManager.canUpdate {
                        Text("Ajouter des joueurs en cliquant sur le bouton \(Image(systemName: "plus"))")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                        Text("Importer des joueurs en cliquant sur le bouton \(Image(systemName: "square.and.arrow.down"))")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, CharterConstants.marginLarge)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(displayedPlayers) { player in
                    HStack {
                        Text(player.name)
                        Spacer()
                        Text("\(player.points)")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if entitlementManager.canUpdate {
                            showManagePlayerView = player
                        }
                    }
                }
                .if(entitlementManager.canUpdate) {
                    $0.onDelete(perform: deletePlayer)
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Rechercher un joueur")
        }
    }

    private func deletePlayer(at offsets: IndexSet) {
        for index in offsets {
            if let playerIndex = players.firstIndex(where: { $0.id == displayedPlayers[index].id }) {
                let player = players[playerIndex]
                firestoreManager.deletePlayer(player)
                dataManager.players.remove(at: playerIndex)
            }
        }
    }

    private func extractLines(from fileURL: URL) {
        _ = fileURL.startAccessingSecurityScopedResource()
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = contents.contains("\r\n")
                ? contents.split(separator: "\r\n").map { String($0) }
                : contents.split(separator: "\n").map { String($0) }

            results = [] // Réinitialiser les résultats
            for line in lines.dropFirst() { // Ignorer l'en-tête
                let components = contents.contains(";")
                    ? line.split(separator: ";").map { String($0) }
                    : line.split(separator: ",").map { String($0) }
                if components.count >= 2 {
                    let name = components[0].trimmingCharacters(in: .whitespaces)
                    let points = Int(components[1].trimmingCharacters(in: .whitespaces)) ?? 9999
                    results.append((name: name, points: points))
                }
            }
            fileURL.stopAccessingSecurityScopedResource()

            addPlayers()
        } catch {
            print("Erreur lors de la lecture du fichier: \(error)")
        }
    }

    private func addPlayers() {
        Task {
            isLoaderPresented = true
            if entitlementManager.userId == nil {
                if let resultId = await firestoreManager.createUser() {
                    entitlementManager.userId = resultId
                    entitlementManager.canUpdate = true
                }
            }
            guard let userId = entitlementManager.userId else { return }

            if !results.isEmpty {
                Analytics.logEvent(LogEvent.importPlayers, parameters: nil)
                for res in results {
                    var player = Player(userId: userId, name: res.name, points: res.points)
                    let playerId = await firestoreManager.insertOrUpdatePlayer(player)
                    guard let playerId else { continue }
                    player.playerId = playerId
                    dataManager.players.append(player)
                }
            }
            isLoaderPresented = false
        }
    }
}
