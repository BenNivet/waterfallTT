//
//  Team.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import Foundation

struct Team: Identifiable, Hashable {
    var id: String { teamId }
    var userId: String
    var teamId: String
    var order: Int
    var name: String
    var division: String
    var location: String
    var atHome: Bool
    
    var formattedLocationName: String {
        if location.isEmpty {
            atHome ? "Domicile" : "Exterieur"
        } else {
            location + " " + (atHome ? "(DOM)" : "(EXT)")
        }
    }

    var teamServer: TeamServer {
        TeamServer(userId: userId,
                   order: order,
                   name: name,
                   division: division,
                   location: location,
                   atHome: atHome)
    }

    init(userId: String = "",
         teamId: String = "",
         order: Int,
         name: String,
         division: String = "",
         location: String = "",
         atHome: Bool = true) {
        self.userId = userId
        self.teamId = teamId
        self.order = order
        self.name = name
        self.division = division
        self.location = location
        self.atHome = atHome
    }

    init(teamServer: TeamServer, documentId: String) {
        teamId = documentId
        userId = teamServer.userId
        order = teamServer.order
        name = teamServer.name
        division = teamServer.division
        location = teamServer.location
        atHome = teamServer.atHome ?? location.isEmpty
    }

    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.teamId == rhs.teamId
    }
}

struct TeamServer: Codable {
    var userId: String
    var order: Int
    var name: String
    var division: String
    var location: String
    var atHome: Bool?
}
