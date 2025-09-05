//
//  WaterfallTTApp.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import FirebaseCore
import SwiftUI

@main
struct WaterfallTTApp: App {
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var dataManager: DataManager

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

//        Task {
//            if !entitlementManager.isPremium,
//               entitlementManager.appLaunched > CharterConstants.minimumAppLaunch {
//                await GADMobileAds.sharedInstance().start()
//            }
//            await subscriptionsManager.updatePurchasedProducts()
//        }
    }

    var body: some Scene {
        WindowGroup {
            InitTabView()
                .environmentObject(entitlementManager)
                .environmentObject(dataManager)
                .fontDesign(.rounded)
        }
    }
}
