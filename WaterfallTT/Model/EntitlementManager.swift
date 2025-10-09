//
//  EntitlementManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 06/10/2024.
//

import SwiftUI

final class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults.standard

    var usersStored: [UserStore] {
        get {
            if let data = EntitlementManager.userDefaults.object(forKey: "usersStored") as? Data,
               let content = try? JSONDecoder().decode([UserStore].self, from: data) {
                content
            } else {
                []
            }
        } set {
            let data = try? JSONEncoder().encode(newValue)
            EntitlementManager.userDefaults.set(data, forKey: "usersStored")
        }
    }

    @AppStorage("userId", store: userDefaults) var userId: String?

    @AppStorage("canUpdate", store: userDefaults) var canUpdate = true

    @AppStorage("appLaunched", store: userDefaults) var appLaunched = 0

    @AppStorage("hasSeenImportInterstitial", store: userDefaults) var hasSeenImportInterstitial = false
    @AppStorage("hasSeenClubIdInterstitial", store: userDefaults) var hasSeenClubIdInterstitial = false

    @discardableResult
    func appendUserIfNeeded(userId: String, canUpdate: Bool) -> UserStore {
        if let userIndex = usersStored.firstIndex(where: { $0.userId == userId }) {
            let oldUser = usersStored[userIndex]
            usersStored.remove(at: userIndex)
            let newUser = UserStore(userId: oldUser.userId, canUpdate: oldUser.canUpdate || canUpdate)
            usersStored.append(newUser)
            return newUser
        } else {
            let user = UserStore(userId: userId, canUpdate: canUpdate)
            usersStored.append(user)
            return user
        }
    }

    func removeUserIfNeeded(userId: String) {
        if let index = usersStored.firstIndex(where: { $0.userId == userId }) {
            usersStored.remove(at: index)
        }
    }
}

struct UserStore: Codable {
    let userId: String
    let canUpdate: Bool
}
