//
//  TeamNameView.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 14/07/2025.
//

import SwiftUI

public struct TeamNameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var newName: String
    @State private var atHome: Bool
    @State private var location: String
    @State private var minPoints: String
    @State private var hasMeetingSchedule: Bool
    @State private var meetingDay: String
    @State private var meetingTime: Date
    @State private var isImportantMatch: Bool

    let team: Team
    private let firestoreManager = FirestoreManager.shared
    private let meetingDays = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var teams: [Team] {
        dataManager.teams
    }

    init(team: Team) {
        self.team = team
        _newName = State(initialValue: team.division)
        _atHome = State(initialValue: team.atHome)
        _location = State(initialValue: team.location)
        _minPoints = State(initialValue: String(team.minPoints))
        _hasMeetingSchedule = State(initialValue: !team.meetingDay.isEmpty || !team.meetingTime.isEmpty)
        _meetingDay = State(initialValue: team.meetingDay.isEmpty ? "Dimanche" : team.meetingDay)
        _meetingTime = State(initialValue: Self.timeFormatter.date(from: team.meetingTime) ?? Self.defaultMeetingTime)
        _isImportantMatch = State(initialValue: team.isImportantMatch)
    }

    public var body: some View {
        VStack(spacing: CharterConstants.margin) {
            teamInformationSection
            meetingSection
            playersRequirementSection
            Spacer()
            Button("Valider") {
                hideKeyboard()
                saveName()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, CharterConstants.marginLarge)
        .padding([.horizontal, .bottom], CharterConstants.margin)
        .keyboardAvoiding()
        .onTapGesture {
            hideKeyboard()
        }
    }

    private var teamInformationSection: some View {
        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
            sectionTitle("Équipe")
            FloatingTextField(placeHolder: String(localized: "Division de l'équipe"),
                              text: $newName)
                .autocorrectionDisabled()
        }
        .sectionContainer()
    }

    private var meetingSection: some View {
        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
            sectionTitle("Rencontre")
            Toggle("Domicile", isOn: $atHome)
            FloatingTextField(placeHolder: atHome ? "Adversaire" : "Lieu de la rencontre",
                              text: $location)
                .autocorrectionDisabled()
            Toggle("Définir le jour et l'heure", isOn: $hasMeetingSchedule)
            if hasMeetingSchedule {
                FloatingTextField(type: .picker(rows: meetingDays),
                                  placeHolder: "Jour",
                                  text: $meetingDay,
                                  rightIcon: "chevron.down")
                DatePicker("Heure", selection: $meetingTime, displayedComponents: .hourAndMinute)
            }
            Toggle("Match à enjeu", isOn: $isImportantMatch)
                .padding(.top, CharterConstants.marginSmall)
        }
        .sectionContainer()
    }

    private var playersRequirementSection: some View {
        VStack(alignment: .leading, spacing: CharterConstants.marginSmall) {
            sectionTitle("Règlement")
            FloatingTextField(placeHolder: "Points min. requis par joueur",
                              text: $minPoints)
                .keyboardType(.numberPad)
        }
        .sectionContainer()
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .bold()
    }

    private static var defaultMeetingTime: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private func saveName() {
        if let index = teams.firstIndex(of: team) {
            var newTeam = teams[index]
            newTeam.division = newName
            newTeam.location = location
            newTeam.atHome = atHome
            let minPoints = Int(minPoints) ?? 0
            newTeam.minPoints = minPoints
            newTeam.meetingDay = hasMeetingSchedule ? meetingDay : ""
            newTeam.meetingTime = hasMeetingSchedule ? Self.timeFormatter.string(from: meetingTime) : ""
            newTeam.isImportantMatch = isImportantMatch
            firestoreManager.updateTeam(newTeam)
            dataManager.teams[index] = newTeam
        }
        dismiss()
    }
}

private extension View {
    func sectionContainer() -> some View {
        padding(CharterConstants.margin)
            .overlay {
                RoundedRectangle(cornerRadius: CharterConstants.radius)
                    .stroke(CharterConstants.halfWhite, lineWidth: 0.5)
            }
    }
}
