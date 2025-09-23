//
//  WaterfallView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import FirebaseAnalytics
import SwiftUI

struct WaterfallView: View {
    @Binding var reload: Bool

    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var isLoaderPresented = false
    @State private var showExitConfirmation = false
    @State private var showResetAllConfirmation = false
    @State private var showResetConfirmation = false
    @State private var showSettings = false
    @State private var showLocations = false
    @State private var selectedTeamIndex: Int?
    @State private var snapshotImage: UIImage?
    @State private var showTeamNameView: Team? = nil
    @State private var sensorFeedback = false
    @State private var shareAlert = false

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

    private var isTeamsEmpty: Bool {
        teams.isEmpty || players.allSatisfy(\.teamId.isEmpty)
    }

    init(reload: Binding<Bool>) {
        _reload = reload
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CharterConstants.margin) {
                    if entitlementManager.canUpdate {
                        HStack {
                            Text("Nombre d’équipes")
                                .font(.headline)
                            Spacer()
                            AnimatedStepper(currentNumber: $dataManager.teamsCount) {
                                Analytics.logEvent(LogEvent.addTeam, parameters: nil)
                                dataManager.teamsCount += 1
                                updateTeamCount()
                            } onDecrement: {
                                Analytics.logEvent(LogEvent.deleteTeam, parameters: nil)
                                dataManager.teamsCount -= 1
                                updateTeamCount()
                            }
                        }
                        .padding(.horizontal, CharterConstants.margin)
                    } else {
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
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .foregroundStyle(.white)
                }
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
                }
                if entitlementManager.canUpdate {
                    ToolbarItem {
                        Button {
                            showLocations = true
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
            .alert("Réinitialiser toutes les équipes ?",
                   isPresented: $showResetConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    clearTeams()
                }
            }
            .alert("Quitter le club ?",
                   isPresented: $showExitConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Quitter", role: .destructive) {
                    exitClub()
                }
            }
            .alert("Supprimer toutes les donnés du club ?",
                   isPresented: $showResetAllConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    resetAll()
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
                        .presentationDetents([.fraction(0.3)])
                }
            }
            .fullScreenCover(isPresented: selectedTeamIndexBinding) {
                if let selectedTeamIndex {
                    SelectPlayerView(teamIndex: selectedTeamIndex,
                                     selectedPlayers: players(at: selectedTeamIndex))
                }
            }
            .fullScreenCover(isPresented: $showLocations) {
                LocationTeamView(homeTeams: teams.filter(\.location.isEmpty))
                    .onDisappear {
                        shareSnapshot()
                    }
            }
            .confirmationDialog("Réglages",
                                isPresented: $showSettings,
                                titleVisibility: .automatic) {
                Button("Quitter le club") {
                    showExitConfirmation = true
                }
                if entitlementManager.canUpdate {
                    Button("Supprimer les données", role: .destructive) {
                        showResetAllConfirmation = true
                    }
                }
                Button("Annuler", role: .cancel) {}
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
                        HStack(spacing: CharterConstants.marginSmall) {
                            Text(teamName(for: index))
                            Image(systemName: "pencil")
                        }
                        .padding(CharterConstants.marginSmall)
                        .font(.headline)
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
        .disabled(!isTeamsEmpty)
    }

    private var reinitButtonView: some View {
        Button("Réinitialiser") {
            showResetConfirmation = true
        }
        .buttonStyle(SecondaryButtonStyle())
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
            guard let userId = await firestoreManager.findUser(id: code) else { return }
            dataManager.reset()
            entitlementManager.userId = userId
            entitlementManager.canUpdate = update
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

    private func resetAll() {
        entitlementManager.userId = nil
        entitlementManager.canUpdate = true
        for player in players {
            firestoreManager.deletePlayer(player)
        }
        for team in teams {
            firestoreManager.deleteTeam(team)
        }
        dataManager.reset()
        Analytics.logEvent(LogEvent.removeAllData, parameters: nil)
    }

    private func exitClub() {
        entitlementManager.userId = nil
        entitlementManager.canUpdate = true
        dataManager.reset()
        Analytics.logEvent(LogEvent.exitClub, parameters: nil)
    }

    private func updateTeamCount() {
        Task {
            isLoaderPresented = true
            if entitlementManager.userId == nil {
                if let resultId = await firestoreManager.createUser() {
                    entitlementManager.userId = resultId
                    entitlementManager.canUpdate = true
                }
            }
            guard let userId = entitlementManager.userId else { return }
            if teamsCount > teams.count {
                let toAdd = teamsCount - teams.count
                for _ in 0 ..< toAdd {
                    var newTeam = Team(userId: userId, order: (sortedTeams.last?.order ?? 0) + 1, name: "Équipe \(teams.count + 1)")
                    if let teamId = await firestoreManager.insertTeam(newTeam) {
                        newTeam.teamId = teamId
                        dataManager.teams.append(newTeam)
                    }
                }
            } else if teamsCount < teams.count {
                let teamsToRemove = teamsCount == 0 ? teams : Array(sortedTeams.suffix(teams.count - teamsCount))
                for team in teamsToRemove {
                    let users = players.filter { $0.teamId == team.teamId }
                    for user in users {
                        guard let index = players.firstIndex(of: user) else { continue }
                        var newUser = user
                        newUser.teamId.removeAll()
                        newUser.isCaptain = false
                        firestoreManager.updatePlayer(newUser)
                        dataManager.players[index] = newUser
                    }
                    firestoreManager.deleteTeam(team)
                }
                dataManager.teams = Array(sortedTeams.prefix(teamsCount))
            }
            isLoaderPresented = false
        }
    }

    private func shareSnapshot() {
        let snapshotView = TeamSnapshotView(teams: sortedTeams, players: players)
        let renderer = ImageRenderer(content: snapshotView)
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
            if players(at: index).count != 4 {
                return Color.orange.opacity(0.6)
            } else {
                return CharterConstants.mainGray
            }
        } else {
            return CharterConstants.mainRed.opacity(0.7)
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
