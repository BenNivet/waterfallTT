//
//  EntitlementManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 06/10/2024.
//

import SwiftUI

final class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults.standard
    
    @AppStorage("userId", store: userDefaults)
    var userId: String?
    
    @AppStorage("appLaunched", store: userDefaults)
    var appLaunched = 0

    @AppStorage("hasSeenImportInterstitial", store: userDefaults)
    var hasSeenImportInterstitial = false
}
