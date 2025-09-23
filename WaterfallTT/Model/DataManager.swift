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
}
