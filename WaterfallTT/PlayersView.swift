//
//  PlayersView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import FirebaseAnalytics
import SwiftUI

struct ImportResult {
    var players: [(name: String, points: Int)] = []
    var clubName: String = ""
    var clubId: String = ""
}

struct PlayersView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var isLoaderPresented = false
    @State private var showAddPlayerView = false
    @State private var showManagePlayerView: Player?
    @State private var showImportDialog = false
    @State private var showDocumentPicker = false
    @State private var showInterstitialPicker = false
    @State private var showInterstitialHelp = false
    @State private var showInterstitialClubId = false
    @State private var showInterstitialClubIdHelp = false
    @State private var showHelpDialog = false
    @State private var searchText = ""
    @State private var results = ImportResult()
    @State private var idClub = ""
    @State private var showingIdClubAlert = false
    @State private var idClubText = ""
    @State private var showDeleteAllConfirmation = false

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
        NavigationStack {
            mainView
                .padding(.vertical, CharterConstants.margin)
                .addLinearGradientBackground()
                .navigationTitle("Joueurs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if entitlementManager.canUpdate {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showImportDialog = true
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
                        if !players.isEmpty {
                            ToolbarItem(placement: .topBarTrailing) {
                                EditButton()
                            }
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showHelpDialog = true
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
                .fullScreenCover(isPresented: $showInterstitialClubId) {
                    ClubIdInterstitialView(isPresented: $showInterstitialClubId)
                        .onDisappear {
                            showingIdClubAlert = true
                        }
                }
                .fullScreenCover(isPresented: $showInterstitialHelp) {
                    ImportInterstitialView(isPresented: $showInterstitialHelp)
                }
                .fullScreenCover(isPresented: $showInterstitialClubIdHelp) {
                    ClubIdInterstitialView(isPresented: $showInterstitialClubIdHelp)
                }
                .sheet(isPresented: $showDocumentPicker) {
                    DocumentPicker { url in
                        if let url {
                            extractLines(from: url)
                        }
                    }
                }
                .confirmationDialog("Import de joueurs",
                                    isPresented: $showImportDialog,
                                    titleVisibility: .visible) {
                    Button("Via FFTT") {
                        if let ffttId = dataManager.user?.ffttId,
                           !ffttId.isEmpty {
                            idClub = ffttId
                        } else {
                            if entitlementManager.hasSeenClubIdInterstitial {
                                showingIdClubAlert = true
                            } else {
                                showInterstitialClubId = true
                            }
                        }
                    }
                    Button("Via fichier Excel (.csv)") {
                        if entitlementManager.hasSeenImportInterstitial {
                            showDocumentPicker = true
                        } else {
                            showInterstitialPicker = true
                        }
                    }
                    Button("Annuler", role: .cancel) {}
                }
                .confirmationDialog("Aide",
                                    isPresented: $showHelpDialog,
                                    titleVisibility: .visible) {
                    Button("Import via identifiant FFTT") {
                        showInterstitialClubIdHelp = true
                    }
                    Button("Import via fichier Excel (.csv)") {
                        showInterstitialHelp = true
                    }
                    Button("Annuler", role: .cancel) {}
                }
                .background {
                    if !idClub.isEmpty {
                        WebViewViewControllerRepresentable(idClub: $idClub,
                                                           results: $results)
                            .opacity(0)
                    }
                }
                .alert("Importer les joueurs", isPresented: $showingIdClubAlert) {
                    TextField("Identifiant FFTT", text: $idClubText)
                        .autocorrectionDisabled()
                    Button("Annuler", role: .cancel) {}
                    Button("OK") {
                        idClub = idClubText
                        idClubText = ""
                    }
                } message: {
                    Text("Veuillez entrer l'identifiant FFTT du club")
                }
                .alert("Supprimer tous les joueurs du club ?", isPresented: $showDeleteAllConfirmation) {
                    Button("Annuler", role: .cancel) {}
                    Button("Supprimer", role: .destructive) {
                        deleteAllPlayers()
                    }
                }
                .onChange(of: idClub) { old, _ in
                    isLoaderPresented.toggle()
                    if !results.players.isEmpty {
                        results.clubId = old
                        addPlayers()
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
                if searchText.isEmpty {
                    removeAllButtonView
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Rechercher un joueur")
        }
    }

    private var removeAllButtonView: some View {
        Button("Tout supprimer") {
            showDeleteAllConfirmation = true
        }
        .buttonStyle(DestructiveButtonStyle())
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

    private func deleteAllPlayers() {
        for player in players {
            firestoreManager.deletePlayer(player)
        }
        dataManager.players.removeAll()
    }

    private func extractLines(from fileURL: URL) {
        _ = fileURL.startAccessingSecurityScopedResource()
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = contents.contains("\r\n")
                ? contents.split(separator: "\r\n").map { String($0) }
                : contents.split(separator: "\n").map { String($0) }

            for line in lines.dropFirst() { // Ignorer l'en-tête
                let components = contents.contains(";")
                    ? line.split(separator: ";").map { String($0) }
                    : line.split(separator: ",").map { String($0) }
                if components.count >= 2 {
                    let name = components[0].trimmingCharacters(in: .whitespaces)
                    let points = Int(components[1].trimmingCharacters(in: .whitespaces)) ?? 9999
                    results.players.append((name: name, points: points))
                }
            }
            fileURL.stopAccessingSecurityScopedResource()

            addPlayers()
        } catch {
            print("Erreur lors de la lecture du fichier: \(error)")
        }
    }

    private func addPlayers() {
        guard !results.players.isEmpty else { return }
        Task {
            isLoaderPresented = true
            if entitlementManager.userId == nil {
                if let user = await firestoreManager.createUser(name: results.clubName, ffttId: results.clubId) {
                    entitlementManager.userId = user.documentId
                    entitlementManager.canUpdate = true
                    entitlementManager.appendUserIfNeeded(userId: user.documentId, canUpdate: true)
                    dataManager.user = user
                }
            } else if let user = dataManager.user {
                let newUser = user
                if newUser.name.isEmpty, !results.clubName.isEmpty {
                    newUser.name = results.clubName
                }
                if !results.clubId.isEmpty {
                    newUser.ffttId = results.clubId
                }
                firestoreManager.updateUser(newUser)
                dataManager.user = newUser
            }
            guard let userId = entitlementManager.userId else { return }

            Analytics.logEvent(LogEvent.importPlayers, parameters: nil)
            for res in results.players {
                var player = Player(userId: userId, name: res.name, points: res.points)
                let playerId = await firestoreManager.insertOrUpdatePlayer(player)
                guard let playerId else { continue }
                player.playerId = playerId
                dataManager.players.append(player)
            }
            isLoaderPresented = false
            results = ImportResult()
        }
    }
}
