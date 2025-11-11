//
//  WaterfallTTApp.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import FirebaseCore
import GoogleMobileAds
import SwiftUI

@main
struct WaterfallTTApp: App {
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var dataManager: DataManager
    @StateObject private var interstitialAdsManager = InterstitialAdsManager()

    init() {
        FirebaseApp.configure()
        let entitlementManager = EntitlementManager()
        entitlementManager.appLaunched += 1
        let dataManager = DataManager()
//        let subscriptionsManager = SubscriptionsManager(entitlementManager: entitlementManager,
//                                                        dataManager: dataManager)
//
        _entitlementManager = StateObject(wrappedValue: entitlementManager)
        _dataManager = StateObject(wrappedValue: dataManager)
//        _subscriptionsManager = StateObject(wrappedValue: subscriptionsManager)

        Task {
            if entitlementManager.appLaunched > CharterConstants.minimumAppLaunch {
                await MobileAds.shared.start()
            }
        }
        if let userId = entitlementManager.userId {
           entitlementManager.appendUserIfNeeded(userId: userId,
                                                 canUpdate: entitlementManager.canUpdate)
        }
    }

    var body: some Scene {
        WindowGroup {
            InitTabView()
                .environmentObject(entitlementManager)
                .environmentObject(dataManager)
                .environmentObject(interstitialAdsManager)
                .fontDesign(.rounded)
        }
    }
}
