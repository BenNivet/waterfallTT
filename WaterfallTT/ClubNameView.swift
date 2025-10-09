//
//  ClubNameView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 02/10/2025.
//

import SwiftUI

public struct ClubNameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var clubName = ""

    private let firestoreManager = FirestoreManager.shared

    init(clubName: String) {
        _clubName = State(initialValue: clubName)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.marginSmall) {
            FloatingTextField(placeHolder: String(localized: "Nom du club"),
                              text: $clubName)
                .autocorrectionDisabled()
            Spacer()
            Button("Valider") {
                hideKeyboard()
                saveName()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(CharterConstants.margin)
        .keyboardAvoiding()
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func saveName() {
        if !clubName.isEmpty,
           let newUser = dataManager.user {
            newUser.name = clubName
            firestoreManager.updateUser(newUser)
            dataManager.user = newUser
        }
        dismiss()
    }
}
