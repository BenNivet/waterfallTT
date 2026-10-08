//
//  Player.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import Foundation

// let names = ["DUPONT", "MARTIN", "LECOMTE", "MOREAU", "GARNIER", "PETIT", "DURAND", "ROBERT", "DUMONT", "LEROY"]
// let firstnames = ["Jean", "Alice", "Sophie", "Louis", "Claire", "Rémi", "Marc", "Thomas", "Paul", "Émilie"]

struct Player: Identifiable, Hashable {
    var id: String { playerId }
    var userId: String
    var playerId: String
    var teamId: String
    var name: String
//    var nameTest: String = { names.randomElement()! + " " + firstnames.randomElement()! }()
    var points: Int
    var isAvailable: Bool
    var isCaptain: Bool
    var lastUpdate: Date?

    var playerServer: PlayerServer {
        PlayerServer(userId: userId,
                     teamId: teamId,
                     name: name,
                     points: points,
                     isAvailable: isAvailable,
                     isCaptain: isCaptain,
                     lastUpdate: lastUpdate.map(Helper.shared.string(from:)))
    }

    init(userId: String = "",
         playerId: String = "",
         teamId: String = "",
         name: String,
         points: Int = 500,
         isAvailable: Bool = true,
         isCaptain: Bool = false,
         lastUpdate: Date? = Date()) {
        self.userId = userId
        self.playerId = playerId
        self.teamId = teamId
        self.name = name
        self.points = points
        self.isAvailable = isAvailable
        self.isCaptain = isCaptain
        self.lastUpdate = lastUpdate
    }

    init(playerServer: PlayerServer, documentId: String) {
        playerId = documentId
        userId = playerServer.userId
        teamId = playerServer.teamId
        name = playerServer.name
        points = playerServer.points
        isAvailable = playerServer.isAvailable
        isCaptain = playerServer.isCaptain
        lastUpdate = if let lastUpdateString = playerServer.lastUpdate {
            Helper.shared.date(from: lastUpdateString)
        } else {
            nil
        }
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.playerId == rhs.playerId
    }
}

struct PlayerServer: Codable {
    var userId: String
    var teamId: String
    var name: String
    var points: Int
    var isAvailable: Bool
    var isCaptain: Bool
    var lastUpdate: String?
}
