//
//  ClubFFTTIdView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 02/10/2025.
//

import SwiftUI

public struct ClubFFTTIdView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var idFFTT = ""

    private let firestoreManager = FirestoreManager.shared

    init(idFFTT: String) {
        _idFFTT = State(initialValue: idFFTT)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.marginSmall) {
            FloatingTextField(placeHolder: String(localized: "Identifiant FFTT du club"),
                              text: $idFFTT)
                .autocorrectionDisabled()
            Spacer()
            Button("Valider") {
                hideKeyboard()
                saveId()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(CharterConstants.margin)
        .keyboardAvoiding()
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func saveId() {
        if !idFFTT.isEmpty,
           let newUser = dataManager.user {
            newUser.ffttId = idFFTT
            firestoreManager.updateUser(newUser)
            dataManager.user = newUser
        }
        dismiss()
    }
}
