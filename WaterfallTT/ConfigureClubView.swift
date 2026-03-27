//
//  ConfigureClubView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 31/12/2025.
//

import FirebaseAnalytics
import SwiftUI

public struct ConfigureClubView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var isLoaderPresented = false
    @State private var idFFTT = ""
    @State private var teamsCount = 1
    @State private var showInterstitialClubIdHelp = false
    @State private var results = ImportResult()
    @State private var fetchByIdClub = ""
    @State private var oldFetchByIdClub = ""
    @State private var showConfetti = false

    @Environment(\.dismiss) var dismiss

    private let firestoreManager = FirestoreManager.shared

    private var oldIdClubBinding: Binding<Bool> {
        Binding {
            !oldFetchByIdClub.isEmpty
        } set: { _ in
            oldFetchByIdClub.removeAll()
        }
    }

    public var body: some View {
        NavigationStack {
            contentView()
                .padding(CharterConstants.margin)
                .addLinearGradientBackground()
                .keyboardAvoiding()
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                .navigationTitle("Configuration")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showInterstitialClubIdHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            closeButtonView
                        }
                    }
                }
                .fullScreenCover(isPresented: $showInterstitialClubIdHelp) {
                    ClubIdInterstitialView(isPresented: $showInterstitialClubIdHelp)
                }
                .loader(isPresented: $isLoaderPresented)
                .background {
                    if !fetchByIdClub.isEmpty {
                        WebViewViewControllerRepresentable(idClub: $fetchByIdClub,
                                                           results: $results,
                                                           canShowAd: .constant(false))
                            .opacity(0)
                    }
                }
                .alert("Erreur", isPresented: oldIdClubBinding) {
                    Button("Annuler", role: .cancel) {}
                    Button("Réessayer") {
                        fetchByIdClub = oldFetchByIdClub
                        oldFetchByIdClub.removeAll()
                    }
                } message: {
                    Text("Une erreur s'est produite lors de l'import des joueurs, voulez-vous réesayer ?")
                }
                .onChange(of: fetchByIdClub) { old, _ in
                    isLoaderPresented.toggle()
                    if !results.players.isEmpty {
                        results.clubId = old
                        addPlayers()
                    } else {
                        oldFetchByIdClub = old
                    }
                }
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        if showConfetti {
            confettiView
        } else {
            VStack(spacing: CharterConstants.margin) {
                FloatingTextField(placeHolder: String(localized: "Identifiant FFTT du club"),
                                  text: $idFFTT)
                    .autocorrectionDisabled()
                HStack {
                    Text("Nombre d’équipes")
                        .font(.headline)
                    Spacer()
                    AnimatedStepper(currentNumber: $teamsCount) {
                        teamsCount += 1
                    } onDecrement: {
                        if teamsCount > 1 {
                            teamsCount -= 1
                        }
                    }
                }
                Spacer()
                Button("Valider") {
                    hideKeyboard()
                    save()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(idFFTT.isEmpty)
            }
        }
    }

    private func save() {
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
            for index in 0 ..< teamsCount {
                var newTeam = Team(userId: userId, order: index, name: "Équipe \(index + 1)")
                if let teamId = await firestoreManager.insertTeam(newTeam) {
                    newTeam.teamId = teamId
                    dataManager.teams.append(newTeam)
                }
            }
            dataManager.teamsCount = dataManager.teams.count
            if !idFFTT.isEmpty,
               let newUser = dataManager.user {
                newUser.ffttId = idFFTT
                firestoreManager.updateUser(newUser)
                dataManager.user = newUser
            }

            isLoaderPresented = true

            fetchByIdClub = idFFTT
        }
    }

    private func addPlayers() {
        guard !results.players.isEmpty else { return }
        Task {
            isLoaderPresented = true
            if let user = dataManager.user {
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

            showConfetti = true
        }
    }

    private var confettiView: some View {
        VStack(spacing: CharterConstants.marginBig) {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow.gradient)
                    .font(Font.system(size: 100))
                Spacer()
            }

            VStack(spacing: CharterConstants.marginMedium) {
                Text("Félicitations")
                    .font(.system(size: 33, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Votre club est configuré !")
                    .font(.system(size: 25, weight: .semibold))
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .ignoresSafeArea()
        .displayConfetti(isActive: $showConfetti)
        .task {
            try? await Task.sleep(for: .seconds(5.5))
            dismiss()
        }
    }
}
