//
//  WaterfallView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import AppTrackingTransparency
import FirebaseAnalytics
import SwiftUI
import UIKit

struct WaterfallView: View {
    @Binding var reload: Bool

    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var interstitialAdsManager: InterstitialAdsManager
    @State private var isLoaderPresented = false
    @State private var showResetConfirmation = false
    @State private var showExportTeams = false
    @State private var selectedTeamIndex: Int?
    @State private var snapshotImage: UIImage?
    @State private var showTeamNameView: Team? = nil
    @State private var sensorFeedback = false
    @State private var shareAlert = false
    @State private var teamsToExport: [Team] = []

    private let firestoreManager = FirestoreManager.shared

    private var snapshotImageBinding: Binding<Bool> {
        Binding {
            snapshotImage != nil
        } set: { _ in
            snapshotImage = nil
        }
    }

    private var selectedTeamIndexBinding: Binding<Bool> {
        Binding {
            selectedTeamIndex != nil
        } set: { _ in
            selectedTeamIndex = nil
        }
    }

    private var showTeamNameViewBinding: Binding<Bool> {
        Binding {
            showTeamNameView != nil
        } set: { _ in
            showTeamNameView = nil
        }
    }

    private var teams: [Team] {
        dataManager.teams
    }

    private var sortedTeams: [Team] {
        teams.sorted { $1.order > $0.order }
    }

    private var players: [Player] {
        dataManager.players
    }

    private var teamsCount: Int {
        dataManager.teamsCount
    }

    private var clubName: String {
        dataManager.user?.name ?? ""
    }

    private var isTeamsEmpty: Bool {
        teams.isEmpty || players.allSatisfy(\.teamId.isEmpty)
    }

    init(reload: Binding<Bool>) {
        _reload = reload
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if teamsCount == 0 {
                    VStack {
                        Spacer()
                        VStack(spacing: CharterConstants.margin) {
                            Text("Aucune équipe")
                                .font(.title)
                            if entitlementManager.canUpdate {
                                Text("1. Importer des joueurs en allant dans l'onglet **Joueurs** \(Image(systemName: "person.3.fill"))")
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                Text("2. Ajouter des équipes en allant dans l'onglet **Réglages** \(Image(systemName: "gearshape.fill"))")
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, CharterConstants.marginLarge)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: CharterConstants.margin) {
                        if !entitlementManager.canUpdate {
                            HStack {
                                Text("Mode lecture seule")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal, CharterConstants.margin)
                        }

                        teamsView
                        if entitlementManager.canUpdate {
                            buttonsView
                        }
                    }
                    .padding(.vertical, CharterConstants.margin)
                }
            }
//            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
//                ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
//            }
            .onReceive(interstitialAdsManager.$interstitialAdLoaded) { isInterstitialAdLoaded in
                if entitlementManager.userId != nil,
                   isInterstitialAdLoaded {
                    interstitialAdsManager.displayInterstitialAd()
                }
            }
            .scrollIndicators(.hidden)
            .toolbar {
                if entitlementManager.userId != nil,
                   entitlementManager.canUpdate {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            shareAlert = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundStyle(.white)
                    }
                    ToolbarItem {
                        Button {
                            showExportTeams = true
                        } label: {
                            Image(systemName: "paperplane")
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .sensoryFeedback(.success, trigger: sensorFeedback)
            .addLinearGradientBackground()
            .navigationTitle("Ping Cascade")
            .navigationSubtitleIfPossible(clubName)
            .alert("Réinitialiser toutes les équipes ?",
                   isPresented: $showResetConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    clearTeams()
                }
            }
            .sheet(isPresented: snapshotImageBinding) {
                if let snapshotImage {
                    ShareSheet(activityItems: [snapshotImage])
                }
            }
            .sheet(isPresented: showTeamNameViewBinding) {
                if let showTeamNameView {
                    TeamNameView(team: showTeamNameView)
                        .presentationDetents([.fraction(0.5)])
                }
            }
            .fullScreenCover(isPresented: selectedTeamIndexBinding) {
                if let selectedTeamIndex {
                    SelectPlayerView(teamIndex: selectedTeamIndex,
                                     selectedPlayers: players(at: selectedTeamIndex))
                }
            }
            .fullScreenCover(isPresented: $showExportTeams) {
                ExportTeamsView(teamsToExportBinding: $teamsToExport)
            }
            .confirmationDialog("Partager l'accès au club",
                                isPresented: $shareAlert,
                                titleVisibility: .visible) {
                if let userId = entitlementManager.userId {
                    ShareLink(item: sharedText(id: userId, update: true),
                              preview: SharePreview("Partager mon club")) {
                        Text("Modification")
                    }
                    ShareLink(item: sharedText(id: userId, update: false),
                              preview: SharePreview("Partager mon club")) {
                        Text("Lecture seule")
                    }
                }
                Button("Annuler", role: .cancel) {}
            }
            .onChange(of: teamsToExport) {
                if !teamsToExport.isEmpty {
                    shareSnapshot(teams: teamsToExport.sorted { $1.order > $0.order })
                }
            }
            .onOpenURL { handleURL($0) }
            .loader(isPresented: $isLoaderPresented)
        }
    }

    private var teamsView: some View {
        ForEach(sortedTeams.indices, id: \.self) { sortedTeamIndex in
            let index = teams.firstIndex(of: sortedTeams[sortedTeamIndex]) ?? 0
            Button {
                if entitlementManager.canUpdate {
                    selectedTeamIndex = index
                }
            } label: {
                VStack {
                    Button {
                        if entitlementManager.canUpdate {
                            showTeamNameView = teams[index]
                        }
                    } label: {
                        VStack(spacing: CharterConstants.marginXSmall) {
                            HStack(spacing: CharterConstants.marginSmall) {
                                Text(teamName(for: index))
                                Image(systemName: "pencil")
                            }
                            .font(.headline)
                            HStack(spacing: CharterConstants.marginSmall) {
                                teams[index].location.isEmpty
                                    ? Image(systemName: "house.fill")
                                    : Image(systemName: "car.fill")
                                Text(teamLocation(for: index))
                            }
                            .font(.subheadline)
                        }
                        .padding(CharterConstants.marginSmall)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                    teamPlayersView(index: index)
                    Spacer()
                }
                .padding(CharterConstants.marginSmall)
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(teamBackgroundColor(for: index, sortedIndex: sortedTeamIndex))
                .cornerRadius(CharterConstants.radius)
            }
        }
        .padding(.horizontal, CharterConstants.margin)
    }

    @ViewBuilder
    private func teamPlayersView(index: Int) -> some View {
        if players(at: index).isEmpty {
            Text("Cliquer-ici pour ajouter des joueurs")
                .font(.footnote)
        } else {
            ForEach(players(at: index).sorted { $0.points > $1.points }, id: \.id) { player in
                HStack(spacing: CharterConstants.marginSmall) {
                    Spacer()
                    Chip(model: ChipModel(isActive: .constant(true),
                                          title: "\(player.name) (\(player.points))") {
                            if entitlementManager.canUpdate {
                                removePlayerFromTeam(player)
                            }
                        })
                        .overlay(alignment: .topLeading) {
                            if player.isCaptain {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow.gradient)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, -CharterConstants.marginSmall)
                                    .padding(.vertical, -CharterConstants.marginSmall)
                            }
                        }
                        .onLongPressGesture {
                            if entitlementManager.canUpdate {
                                sensorFeedback.toggle()
                                toggleCaptain(of: player)
                            }
                        }
                    Spacer()
                }
                .padding(.horizontal, CharterConstants.margin)
            }
        }
    }

    private var buttonsView: some View {
        VStack(spacing: CharterConstants.marginSmall) {
            fillButtonView
            reinitButtonView
        }
        .padding(.horizontal, CharterConstants.margin)
    }

    private var fillButtonView: some View {
        Button("Remplir automatiquement") {
            assignPlayersToTeams()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!isTeamsEmpty || players.isEmpty)
    }

    private var reinitButtonView: some View {
        Button("Réinitialiser") {
            showResetConfirmation = true
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(isTeamsEmpty)
    }

    func handleURL(_ url: URL) {
        guard let host = url.host() else { return }
        if host == "code" {
            let code = url.lastPathComponent
            let codeArray = code.components(separatedBy: "-")
            if let userId = codeArray.first {
                findTeams(code: userId, update: codeArray.last != "0")
            }
        }
    }

    private func findTeams(code: String, update: Bool) {
        Task {
            guard let user = await firestoreManager.fetchUser(for: code) else { return }
            dataManager.reset()
            let userStore = entitlementManager.appendUserIfNeeded(userId: user.documentId, canUpdate: update)
            entitlementManager.userId = userStore.userId
            entitlementManager.canUpdate = userStore.canUpdate
            reload = true
        }
    }

    private func removePlayerFromTeam(_ player: Player) {
        if let index = players.firstIndex(where: { $0 == player }) {
            var newPlayer = players[index]
            newPlayer.teamId.removeAll()
            if player.isCaptain {
                newPlayer.isCaptain = false
                if let otherIndex = players.firstIndex(where: { $0.teamId == player.teamId }) {
                    var otherPlayer = players[otherIndex]
                    otherPlayer.isCaptain = true
                    firestoreManager.updatePlayer(otherPlayer)
                    dataManager.players[otherIndex] = otherPlayer
                }
            }
            firestoreManager.updatePlayer(newPlayer)
            dataManager.players[index] = newPlayer
            Analytics.logEvent(LogEvent.updateTeam, parameters: nil)
        }
    }

    private func clearTeams() {
        for i in teams.indices {
            var team = teams[i]
            team.location.removeAll()
            firestoreManager.updateTeam(team)
            dataManager.teams[i] = team
        }
        for j in players.indices {
            var player = players[j]
            player.teamId.removeAll()
            player.isCaptain = false
            firestoreManager.updatePlayer(player)
            dataManager.players[j] = player
        }
        Analytics.logEvent(LogEvent.reinitTeams, parameters: nil)
    }

    private func totalPoints(_ index: Int) -> Int {
        players(at: index).reduce(0) { $0 + $1.points }
    }

    private func players(at index: Int) -> [Player] {
        players.filter { $0.teamId == teams[index].teamId }
    }

    private func assignPlayersToTeams() {
        clearTeams()

        var assignablePlayers = players.filter(\.isAvailable).sorted { $0.points > $1.points }
        var addedPlayers = [Player]()

        for i in 0 ..< teamsCount {
            let teamIndex = teams.firstIndex(of: sortedTeams[i]) ?? 0
            for _ in 0 ..< 4 {
                if let player = assignablePlayers.first {
                    if let index = players.firstIndex(where: { $0 == player }) {
                        var newPlayer = players[index]
                        if players(at: teamIndex).isEmpty {
                            newPlayer.isCaptain = true
                        }
                        newPlayer.teamId = teams[teamIndex].teamId
                        firestoreManager.updatePlayer(newPlayer)
                        dataManager.players[index] = newPlayer
                    }
                    addedPlayers.append(player)
                    assignablePlayers.removeFirst()
                }
            }
        }
        Analytics.logEvent(LogEvent.fillTeams, parameters: nil)
    }

    private func shareSnapshot(teams: [Team]) {
        let snapshotView = TeamSnapshotView(teams: teams, players: players)
        let renderer = ImageRenderer(content: snapshotView)
        renderer.proposedSize = ProposedViewSize(CGSize(width: 595.2, height: 841.8))
        if let image = renderer.uiImage {
            Analytics.logEvent(LogEvent.exportTeams, parameters: nil)
            snapshotImage = image
        }
    }

    private func teamBackgroundColor(for index: Int, sortedIndex: Int) -> Color {
        guard !players(at: index).isEmpty else { return CharterConstants.mainGray }
        let total = totalPoints(index)
        if sortedTeams.indices.filter({ $0 > sortedIndex }).allSatisfy({
            guard let newIndex = teams.firstIndex(of: sortedTeams[$0]) else { return false }
            return totalPoints(newIndex) < total
        }) {
            if players(at: index).count < 4 {
                return Color.orange.opacity(0.6)
            } else {
                return CharterConstants.mainGray
            }
        } else {
            return dataManager.user?.cascade ?? true
                ? CharterConstants.mainRed.opacity(0.7)
                : CharterConstants.mainGray
        }
    }

    private func toggleCaptain(of player: Player) {
        if player.isCaptain { return }
        if let oldCaptainIndex = players.firstIndex(where: { $0.isCaptain && $0.teamId == player.teamId }) {
            var oldCaptain = players[oldCaptainIndex]
            oldCaptain.isCaptain = false
            firestoreManager.updatePlayer(oldCaptain)
            dataManager.players[oldCaptainIndex] = oldCaptain
        }
        if let otherIndex = players.firstIndex(where: { $0.id == player.id }) {
            var otherPlayer = players[otherIndex]
            otherPlayer.isCaptain = true
            firestoreManager.updatePlayer(otherPlayer)
            dataManager.players[otherIndex] = otherPlayer
        }
        Analytics.logEvent(LogEvent.updateCaptainPlayer, parameters: nil)
    }

    private func teamName(for index: Int) -> String {
        "\(teams[index].name)" + (teams[index].division.isEmpty ? "" : " - \(teams[index].division)") + " (\(totalPoints(index)) pts)"
    }

    private func teamLocation(for index: Int) -> String {
        teams[index].location.isEmpty ? "Domicile" : "\(teams[index].location)"
    }

    func sharedText(id: String, update: Bool) -> String {
        String(localized:
            """
            Ping Cascade
            Rejoins le club !
            Clic sur le lien ci-dessous pour y acceder :
            waterfalltt://code/\(id)\(update ? "" : "-0")
            L'application Ping Cascade doit déjà être installée sur le téléphone.
            """)
    }
}
