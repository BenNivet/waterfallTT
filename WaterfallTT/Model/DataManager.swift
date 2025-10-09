//
//  DataManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 18/11/2024.
//

import Foundation
import Combine

final class DataManager: ObservableObject {
    @Published var user: User?
    @Published var players: [Player] = []
    @Published var teams: [Team] = []
    @Published var teamsCount = 0

    func reset() {
        user = nil
        players.removeAll()
        teams.removeAll()
        teamsCount = 0
    }
}
