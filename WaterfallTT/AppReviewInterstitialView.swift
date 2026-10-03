//
//  AppReviewInterstitialView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 28/09/2026.
//

import SwiftUI

struct AppReviewInterstitialView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: CharterConstants.marginLarge) {
            Spacer()
            Image(systemName: "star.bubble.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            Text("L'application vous plaît ?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Créée par un pongiste, pour les pongistes, Ping Cascade a besoin de vous.\nUne note et un commentaire soutiennent le travail bénévole et permettent de continuer à faire vivre et évoluer l'application, pensée avant tout pour vous.")
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: CharterConstants.margin) {
                Button("Noter l'application") {
                    markAsSeen()
                    guard let url =
                        URL(string: "https://apps.apple.com/fr/app/ping-cascade-tennis-de-table/id6749312688?action=write-review")
                    else { return }
                    openURL(url)
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Plus tard") {
                    markAsSeen()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(CharterConstants.margin)
        .addLinearGradientBackground()
    }

    private func markAsSeen() {
        entitlementManager.hasSeenAppReviewInterstitial = true
    }
}
