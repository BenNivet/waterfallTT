//
//  SettingsView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 01/10/2025.
//

import FirebaseAnalytics
import MessageUI
import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.requestReview) private var requestReview

    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var isLoaderPresented = false
    @State private var showSelectClub = false
    @State private var showNameClub = false
    @State private var showIdFFTTClub = false
    @State private var showExitConfirmation = false
    @State private var showResetAllConfirmation = false
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil

    private let firestoreManager = FirestoreManager.shared

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

    private var ffttClubId: String {
        dataManager.user?.ffttId ?? ""
    }

    private var cascadeModeBinding: Binding<Bool> {
        Binding {
            dataManager.user?.cascade ?? true
        }
        set: { newValue in
            if let newUser = dataManager.user {
                newUser.cascade = newValue
                firestoreManager.updateUser(newUser)
                dataManager.user = newUser
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CharterConstants.margin) {
                    section("Infos du club")
                    if entitlementManager.userId != nil {
                        clubNameView
                        idClubView
                        toggleCascadeView
                    }

                    numberTeamsView

                    if !entitlementManager.usersStored.isEmpty {
                        section("Gestion")
                        clubsButtonView
                    }

                    if entitlementManager.userId != nil {
                        section("Paramètre du compte")
                        buttonsView
                    }

                    rateButton

                    if MFMailComposeViewController.canSendMail() {
                        Button("Demande de support") {
                            showingMailView = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    Spacer()
                }
                .padding(CharterConstants.margin)
            }
            .scrollIndicators(.hidden)
            .keyboardAvoiding()
            .onTapGesture {
                hideKeyboard()
            }
            .padding(.vertical, CharterConstants.margin)
            .addLinearGradientBackground()
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSelectClub) {
                ClubListView(clubId: entitlementManager.userId ?? "")
                    .presentationDetents(entitlementManager.usersStored.count > 3 ? [.large] : [.medium, .large])
            }
            .sheet(isPresented: $showNameClub) {
                ClubNameView(clubName: clubName)
                    .presentationDetents([.fraction(0.3)])
            }
            .sheet(isPresented: $showIdFFTTClub) {
                ClubFFTTIdView(idFFTT: ffttClubId)
                    .presentationDetents([.fraction(0.3)])
            }
            .alert("Quitter le club ?",
                   isPresented: $showExitConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Quitter", role: .destructive) {
                    exitClub()
                }
            }
            .sheet(isPresented: $showingMailView) {
                MailView(result: $mailResult)
            }
            .alert("Supprimer toutes les donnés du club ?",
                   isPresented: $showResetAllConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    resetAll()
                }
            }
            .loader(isPresented: $isLoaderPresented)
        }
    }

    private func section(_ name: String) -> some View {
        HStack {
            Text(name)
                .font(.title2.bold())
            Spacer()
        }
        .padding(.vertical, CharterConstants.marginSmall)
    }

    private var clubNameView: some View {
        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
            Text("Nom")
                .font(.headline)
            Button {
                showNameClub = true
            } label: {
                HStack {
                    Text(clubName.isEmpty ? "Nom du club" : clubName)
                        .foregroundStyle(clubName.isEmpty ? CharterConstants.halfWhite : .white)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.headline)
                }
                .padding(CharterConstants.margin)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var idClubView: some View {
        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
            Text("Identifiant FFTT")
                .font(.headline)
            Button {
                showIdFFTTClub = true
            } label: {
                HStack {
                    Text(ffttClubId.isEmpty ? "Identifiant FFTT du club" : ffttClubId)
                        .foregroundStyle(ffttClubId.isEmpty ? CharterConstants.halfWhite : .white)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.headline)
                }
                .padding(CharterConstants.margin)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var toggleCascadeView: some View {
        Toggle("Mode Cascade", isOn: cascadeModeBinding)
            .font(.headline)
            .padding(.vertical, CharterConstants.marginSmall)
    }

    private var numberTeamsView: some View {
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
    }

    private var clubsButtonView: some View {
        Button {
            showSelectClub = true
        } label: {
            HStack {
                Text(entitlementManager.userId == nil ? "Choisir un club" : "Changer de club")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .padding(CharterConstants.margin)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var buttonsView: some View {
        VStack(spacing: CharterConstants.margin) {
            Button("Quitter le club") {
                showExitConfirmation = true
            }
            .buttonStyle(SecondaryButtonStyle())

            if entitlementManager.canUpdate {
                Button("Supprimer toutes les données") {
                    showResetAllConfirmation = true
                }
                .buttonStyle(DestructiveButtonStyle())
            }
        }
    }

    private var rateButton: some View {
        Button("Noter l'application") {
            requestReview()
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private func updateTeamCount() {
        Task {
            isLoaderPresented = true
            if entitlementManager.userId == nil {
                if let user = await firestoreManager.createUser() {
                    entitlementManager.userId = user.documentId
                    entitlementManager.canUpdate = true
                    entitlementManager.appendUserIfNeeded(userId: user.documentId, canUpdate: true)
                    dataManager.user = user
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

    private func resetAll() {
        if let userId = entitlementManager.userId {
            entitlementManager.removeUserIfNeeded(userId: userId)
            firestoreManager.deleteUser(userId)
        }
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
        selectNewUserIfPossible()
    }

    private func exitClub() {
        if let userId = entitlementManager.userId {
            entitlementManager.removeUserIfNeeded(userId: userId)
        }
        entitlementManager.userId = nil
        entitlementManager.canUpdate = true
        dataManager.reset()
        Analytics.logEvent(LogEvent.exitClub, parameters: nil)
        selectNewUserIfPossible()
    }

    private func selectNewUserIfPossible() {
        if let newUser = entitlementManager.usersStored.first,
           let url = URL(string: "waterfalltt://code/\(newUser.userId)\(newUser.canUpdate ? "" : "-0")") {
            UIApplication.shared.open(url)
        }
    }
}
