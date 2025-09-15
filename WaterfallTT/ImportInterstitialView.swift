//
//  ImportInterstitialView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 11/09/2025.
//

import SwiftUI

struct ImportInterstitialView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.dismiss) var dismiss

    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: CharterConstants.margin) {
                ScrollView {
                    VStack(spacing: CharterConstants.margin) {
                        Text("Pour importer des joueurs, veuillez utiliser un fichier CSV avec deux colonnes")
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("• La première colonne doit contenir le nom et le prénom du joueur\n• La seconde colonne doit contenir son nombre de points FFTT")
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Image("IntestitialImage")
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
            .navigationTitle("Import de joueurs")
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
            entitlementManager.hasSeenImportInterstitial = true
            isPresented = false
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
