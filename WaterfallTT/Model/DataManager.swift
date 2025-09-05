//
//  DataManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 18/11/2024.
//

import Foundation
import Combine

final class DataManager: ObservableObject {
    @Published var players: [Player] = []
    @Published var teams: [Team] = []
    @Published var teamsCount = 0

    func reset() {
        players.removeAll()
        teams.removeAll()
        teamsCount = 0
    }
    
    private func saveData() {
//        let encoder = JSONEncoder()
//        if let playersData = try? encoder.encode(players),
//           let teamsData = try? encoder.encode(teams) {
//            UserDefaults.standard.set(playersData, forKey: UserDefaultsKeys.playersKey)
//            UserDefaults.standard.set(teamsData, forKey: UserDefaultsKeys.teamsKey)
//            UserDefaults.standard.set(teamsCount, forKey: UserDefaultsKeys.teamsCountKey)
//        }
    }
}
