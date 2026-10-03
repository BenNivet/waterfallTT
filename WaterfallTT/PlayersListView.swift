//
//  PlayersListView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 28/09/2026.
//

import SwiftUI

struct PlayersListView: View {
    let players: [Player]
    let canUpdate: Bool
    @Binding var searchText: String
    @Binding var isSelecting: Bool
    @Binding var selectedPlayerIDs: Set<String>
    let onPlayerTap: (Player) -> Void
    let onDelete: (IndexSet) -> Void
    let onDeleteAll: () -> Void
    let onDeleteSelected: () -> Void

    var body: some View {
        List {
            if canUpdate, !isSelecting {
                ForEach(players) { player in
                    playerRow(player)
                }
                .onDelete(perform: onDelete)
            } else {
                ForEach(players) { player in
                    playerRow(player)
                }
            }

            if searchText.isEmpty, !isSelecting {
                Button("Tout supprimer") {
                    onDeleteAll()
                }
                .buttonStyle(DestructiveButtonStyle())
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Rechercher un joueur")
    }

    private func playerRow(_ player: Player) -> some View {
        HStack {
            if isSelecting {
                selectionImage(for: player)
            }
            Text(player.name)
            Spacer()
            Text(String(player.points))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                toggleSelection(of: player)
            } else if canUpdate {
                onPlayerTap(player)
            }
        }
    }

    private func selectionImage(for player: Player) -> some View {
        let isSelected = selectedPlayerIDs.contains(player.id)
        return Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isSelected ? Color.blue : Color.secondary)
    }

    private func toggleSelection(of player: Player) {
        if selectedPlayerIDs.contains(player.id) {
            selectedPlayerIDs.remove(player.id)
        } else {
            selectedPlayerIDs.insert(player.id)
        }
    }
}
