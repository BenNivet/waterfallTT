//
//  FirestoreManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 08/12/2023.
//

import FirebaseFirestore
import Foundation

@MainActor
class FirestoreManager {
    enum Table: String {
        case users = "Users"
        case teams = "Teams"
        case players = "Players"
    }

    enum Column: String {
        case userId
        case name
    }

    static let shared = FirestoreManager()
    var db: Firestore?

    init() {
        db = Firestore.firestore()
    }

    func createUser(name: String = "", ffttId: String = "") async -> User? {
        do {
            let userServer = UserServer(name: name, ffttId: ffttId)
            let document = try await db?.collection(Table.users.rawValue)
                .addDocument(from: userServer)
            guard let document else { return nil }

            return User(userServer: userServer, documentId: document.documentID)
        } catch {
            return nil
        }
    }

    func fetchUser(for userId: String) async -> User? {
        do {
            let documentSnapshot = try await db?.collection(Table.users.rawValue)
                .document(userId)
                .getDocument()
            guard let documentSnapshot,
                  documentSnapshot.exists,
                  let userServer = try? documentSnapshot.data(as: UserServer.self)
            else { return nil }

            return User(userServer: userServer,
                        documentId: documentSnapshot.documentID)
        } catch {
            return nil
        }
    }

    func fetchUsers(for usersId: [String]) async -> [User] {
        do {
            let querySnapshot = try await db?.collection(Table.users.rawValue)
                .whereField(FieldPath.documentID(), in: usersId)
                .getDocuments()
            guard let documents = querySnapshot?.documents
            else { return [] }

            return documents
                .compactMap { userData -> User? in
                    guard let userServer = try? userData.data(as: UserServer.self)
                    else { return nil }
                    return User(userServer: userServer,
                                documentId: userData.documentID)
                }

        } catch {
            return []
        }
    }

    func fetchAllUsers() async -> [User] {
        do {
            let querySnapshot = try await db?.collection(Table.users.rawValue)
                .whereField(Column.name.rawValue, isNotEqualTo: "")
                .getDocuments()
            guard let documents = querySnapshot?.documents
            else { return [] }

            return documents
                .compactMap { userData -> User? in
                    guard let userServer = try? userData.data(as: UserServer.self)
                    else { return nil }
                    return User(userServer: userServer,
                                documentId: userData.documentID)
                }

        } catch {
            return []
        }
    }

    func fetchTeams(for userId: String) async -> [Team] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                db?.collection(Table.teams.rawValue)
                    .whereField(Column.userId.rawValue, isEqualTo: userId)
                    .getDocuments { querySnapshot, _ in
                        guard let documents = querySnapshot?.documents
                        else {
                            continuation.resume(returning: [])
                            return
                        }
                        continuation.resume(returning: documents
                            .compactMap { teamData -> Team? in
                                guard let teamServer = try? teamData.data(as: TeamServer.self)
                                else { return nil }
                                return Team(teamServer: teamServer,
                                            documentId: teamData.documentID)
                            })
                    }
            }
        } catch {
            return []
        }
    }

    func fetchPlayers(for userId: String) async -> [Player] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                db?.collection(Table.players.rawValue)
                    .whereField(Column.userId.rawValue, isEqualTo: userId)
                    .getDocuments { querySnapshot, _ in
                        guard let documents = querySnapshot?.documents
                        else {
                            continuation.resume(returning: [])
                            return
                        }
                        continuation.resume(returning: documents
                            .compactMap { playerData -> Player? in
                                guard let playerServer = try? playerData.data(as: PlayerServer.self)
                                else { return nil }
                                return Player(playerServer: playerServer,
                                              documentId: playerData.documentID)
                            })
                    }
            }
        } catch {
            return []
        }
    }

    func insertTeam(_ team: Team) async -> String? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                var ref: DocumentReference?
                ref = try? db?.collection(Table.teams.rawValue)
                    .addDocument(from: team.teamServer) { _ in
                        continuation.resume(returning: ref?.documentID)
                    }
            }
        } catch {
            return nil
        }
    }

    func insertOrUpdatePlayer(_ player: Player) async -> String? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                if player.playerId.isEmpty {
                    var ref: DocumentReference?
                    ref = try? db?.collection(Table.players.rawValue)
                        .addDocument(from: player.playerServer) { _ in
                            continuation.resume(returning: ref?.documentID)
                        }
                } else {
                    try? db?.collection(Table.players.rawValue)
                        .document(player.playerId)
                        .setData(from: player.playerServer)
                    continuation.resume(returning: player.playerId)
                }
            }
        } catch {
            return nil
        }
    }

    func updateTeam(_ team: Team) {
        try? db?.collection(Table.teams.rawValue)
            .document(team.teamId)
            .setData(from: team.teamServer)
    }

    func updatePlayer(_ player: Player) {
        try? db?.collection(Table.players.rawValue)
            .document(player.playerId)
            .setData(from: player.playerServer)
    }

    func updateUser(_ user: User) {
        try? db?.collection(Table.users.rawValue)
            .document(user.documentId)
            .setData(from: user.userServer)
    }

    func deleteTeam(_ team: Team) {
        db?.collection(Table.teams.rawValue)
            .document(team.teamId)
            .delete()
    }

    func deletePlayer(_ player: Player) {
        db?.collection(Table.players.rawValue)
            .document(player.playerId)
            .delete()
    }

    func deleteUser(_ userId: String) {
        db?.collection(Table.users.rawValue)
            .document(userId)
            .delete()
    }

    func fetchAllPlayers() async -> [Player] {
        do {
            let querySnapshot = try await db?.collection(Table.players.rawValue)
                .whereField(Column.userId.rawValue, isNotEqualTo: "")
                .getDocuments()
            guard let documents = querySnapshot?.documents
            else { return [] }

            return documents
                .compactMap { playerData -> Player? in
                    guard let playerServer = try? playerData.data(as: PlayerServer.self)
                    else { return nil }
                    return Player(playerServer: playerServer,
                                  documentId: playerData.documentID)
                }

        } catch {
            return []
        }
    }
}
