//
//  User.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 30/07/2025.
//

import Foundation

class User {
    private let id = UUID()
    var documentId: String
    var date: String
    var name: String
    var ffttId: String
    var cascade: Bool

    var userServer: UserServer {
        UserServer(name: name, ffttId: ffttId, date: date, cascade: cascade)
    }

    init(documentId: String = "", name: String = "", ffttId: String = "", cascade: Bool = true) {
        self.documentId = documentId
        date = Helper.shared.creationDate
        self.name = name
        self.ffttId = ffttId
        self.cascade = cascade
    }

    init(userServer: UserServer, documentId: String) {
        self.documentId = documentId
        name = userServer.name
        ffttId = userServer.ffttId ?? ""
        date = userServer.date
        cascade = userServer.cascade ?? true
    }
}

struct UserServer: Codable {
    var name: String
    var ffttId: String?
    var date: String = Helper.shared.creationDate
    var cascade: Bool?
}
