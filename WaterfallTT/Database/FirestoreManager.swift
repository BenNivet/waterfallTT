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
    }

    static let shared = FirestoreManager()
    var db: Firestore?

    init() {
        db = Firestore.firestore()
    }

    func findUser(id: String) async -> String? {
        guard !id.isEmpty else { return nil }
        do {
            return try await withCheckedThrowingContinuation { continuation in
                db?.collection(Table.users.rawValue).document(id)
                    .getDocument { documentSnapshot, _ in
                        if let documentSnapshot,
                           documentSnapshot.exists {
                            continuation.resume(returning: documentSnapshot.documentID)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
            }
        } catch {
            return nil
        }
    }

    func createUser(name: String = "") async -> String? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                var ref: DocumentReference?
                ref = try? db?.collection(Table.users.rawValue)
                    .addDocument(from: UserServer(name: name)) { _ in
                        continuation.resume(returning: ref?.documentID)
                    }
            }
        } catch {
            return nil
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
}
