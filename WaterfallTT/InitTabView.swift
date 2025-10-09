//
//  InitTabView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 01/11/2023.
//

import FirebaseAnalytics
import SwiftUI

struct InitTabView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var isLoaderPresented = true
    @State private var reload = false
    @State private var dataFetched = false

    private let firestoreManager = FirestoreManager.shared

    var body: some View {
        main
            .onChange(of: reload) { _, newValue in
                if newValue {
                    Task {
                        isLoaderPresented = true
                        await fetchFromServer()
                    }
                }
            }
            .loader(isPresented: $isLoaderPresented)
    }

    @ViewBuilder private var main: some View {
        if !dataFetched {
            NavigationStack {
                Image("wallpaper1")
                    .resizable()
                    .ignoresSafeArea()
                    .navigationTitle(String(localized: "Ping Cascade"))
            }
            .task {
                await fetchFromServer()
            }
        } else {
            TabView {
                WaterfallView(reload: $reload)
                    .tabItem {
                        Text("Équipes")
                        Image(systemName: "star.fill")
                    }
                AvailabilityView()
                    .tabItem {
                        Text("Disponibilités")
                        Image(systemName: "person.fill.checkmark.and.xmark")
                    }
                PlayersView()
                    .tabItem {
                        Text("Joueurs")
                        Image(systemName: "person.3.fill")
                    }
                SettingsView()
                    .tabItem {
                        Text("Réglages")
                        Image(systemName: "gearshape.fill")
                    }
            }
            .accentColor(.white)
            .onAppear {
                UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
            }
        }
    }

    private func fetchFromServer() async {
        if let userId = entitlementManager.userId {
            await fetch(userId: userId)
        } else {
            dataFetched = true
            isLoaderPresented = false
        }
    }

    private func fetch(userId: String) async {
        async let user = firestoreManager.fetchUser(for: userId)
        async let teams = firestoreManager.fetchTeams(for: userId)
        async let players = firestoreManager.fetchPlayers(for: userId)
        await updateModel(user, teams: teams, players: players)
    }

    private func updateModel(_ user: User?, teams: [Team], players: [Player]) {
        dataManager.user = user
        dataManager.teams = teams
        dataManager.players = players
        dataManager.teamsCount = teams.count
        endFetch()
        log(teams: teams, players: players)
    }

    private func endFetch() {
        if reload {
            reload = false
        }
        dataFetched = true
        isLoaderPresented = false
    }

    private func log(teams: [Team], players: [Player]) {
        // Teams
        Analytics.logEvent(LogEvent.teamsCountTotal, parameters: nil)
        Analytics.logEvent(LogEvent.teamsCount + String(Int(floor(Float(teams.count) / 10) * 10)),
                           parameters: nil)

        // Players
        Analytics.logEvent(LogEvent.playersCountTotal, parameters: nil)
        Analytics.logEvent(LogEvent.playersCount + String(Int(floor(Float(players.count) / 10) * 10)),
                           parameters: nil)
    }
}
