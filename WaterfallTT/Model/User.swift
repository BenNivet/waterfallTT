//
//  User.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 30/07/2025.
//

import Foundation

class User {
    var id: UUID = UUID()
    var documentId: String = ""
    var date: String = ""
    var name: String = ""
    var ffttId: String = ""

    var userServer: UserServer {
        UserServer(name: name, ffttId: ffttId, date: date)
    }

    init(documentId: String = "", name: String = "", ffttId: String = "") {
        self.documentId = documentId
        self.name = name
        self.ffttId = ffttId
    }

    init(userServer: UserServer, documentId: String) {
        self.documentId = documentId
        name = userServer.name
        ffttId = userServer.ffttId ?? ""
        date = userServer.date
    }
}

struct UserServer: Codable {
    var name: String
    var ffttId: String?
    var date: String = Helper.shared.creationDate
}
