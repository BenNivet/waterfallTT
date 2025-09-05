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
    var name: String = ""

    init(documentId: String = "", name: String = "") {
        self.documentId = documentId
        self.name = name
    }

    init(userServer: UserServer) {
        name = userServer.name
    }
}

struct UserServer: Codable {
    var name: String
    var date: String = Helper.shared.creationDate
}
