//
//  ClubIdInterstitialView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 11/09/2025.
//

import SwiftUI

struct ClubIdInterstitialView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.dismiss) var dismiss

    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: CharterConstants.margin) {
                ScrollView {
                    VStack(spacing: CharterConstants.margin) {
                        Text("Pour trouver l'identifiant FFTT de votre club, vous pouver vous rendre sur l'application FFTT et trouver le numero dans le detail de votre club.")
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Image("InterstitialClubIdImage")
                            .resizable()
                            .scaledToFit()
                            .padding(.vertical, CharterConstants.marginMedium)
                            .padding(.horizontal, CharterConstants.margin)
                    }
                }

                understoodButton
            }
            .padding(CharterConstants.margin)
            .scrollIndicators(.hidden)
            .addLinearGradientBackground()
            .navigationTitle("Identifiant FFTT")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        closeButtonView
                    }
                }
            }
        }
    }

    private var understoodButton: some View {
        Button("Ne plus afficher") {
            entitlementManager.hasSeenClubIdInterstitial = true
            isPresented = false
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
