//
//  Constants.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 01/11/2023.
//

import Foundation
import SwiftUI

struct CharterConstants {
    // Margins
    static let margin: CGFloat = 16
    static let marginXXSmall: CGFloat = 2
    static let marginXSmall: CGFloat = 4
    static let marginSmall: CGFloat = 8
    static let marginMedium: CGFloat = 24
    static let marginLarge: CGFloat = 32
    static let marginBig: CGFloat = 40
    static let marginHuge: CGFloat = 48

    static let buttonSize: CGFloat = 45
    static let quantitySize: CGFloat = 40

    /// Radius
    static let radius: CGFloat = 12

    // Color
    static let mainColor: Color = Color(UIColor(hexString: "#6600cc"))
    static let mainRed: Color = Color(UIColor(hexString: "#D13E46"))
    static let halfWhite: Color = .white.opacity(0.6)
    static let halfGray: Color = .gray.opacity(0.6)
    static let mainGray: Color = Color(.systemGray5)

    // Alpha Transparency
    static let alphaFifteen: CGFloat = 0.15
    static let alphaThirty: CGFloat = 0.3

    /// Opacity
    static let disabledOpacity: CGFloat = 0.4

    /// Random
    static let minimumAppLaunch = 10
}

struct UserDefaultsKeys {
    static let playersKey = "players"
    static let teamsKey = "teams"
    static let teamsCountKey = "teamsCount"
}

// struct ScreenName {
//    static let wineList = "Wine_list"
//    static let emptyWineList = "Wine_list_empty"
//    static let addWine = "Add_wine"
//    static let addWinePrice = "Add_wine_price"
//    static let yearList = "Year_list"
//    static let subscription = "Subscription"
//    static let subscriptionSuccess = "Subscription_success"
//    static let random = "Random"
//    static let randomResult = "Random_result"
//    static let stats = "Stats"
//    static let scanWine = "Scan_wine"
//    static let selectWineName = "Select_wine_name"
//    static let newFeatures = "New_featuresV2"
// }

struct LogEvent {
    static let addTeam = "Add_team"
    static let updateTeam = "Update_team"
    static let deleteTeam = "Delete_team"

    static let addPlayer = "Add_player"
    static let importPlayers = "Import_players"
    static let updatePlayer = "Update_player"
    static let deletePlayer = "Delete_player"
    static let updateAvailabilityPlayer = "Update_availability_player"
    static let updateCaptainPlayer = "Update_captain_player"

    static let fillTeams = "Fill_teams"
    static let reinitTeams = "Reinit_teams"

    static let teamsCountTotal = "Teams_count_total"
    static let teamsCount = "Teams_count_"
    static let playersCountTotal = "Players_count_total"
    static let playersCount = "Players_count_"

    static let removeAllData = "Remove_all_data"
    static let exitClub = "Exit_club"
    static let exportTeams = "Export_teams"
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a: UInt32
        let r: UInt32
        let g: UInt32
        let b: UInt32

        (a, r, g, b) = switch hex.count {
        case 3: // RGB (12-bit)
            (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (255, 0, 0, 0)
        }

        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension String {
    var queryFormatted: String {
        folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }
}
