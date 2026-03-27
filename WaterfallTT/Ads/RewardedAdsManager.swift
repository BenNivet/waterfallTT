//
//  RewardedAdsManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 25/03/2026.
//

import GoogleMobileAds
import UIKit

@MainActor
class RewardedAdsManager: NSObject, ObservableObject, FullScreenContentDelegate {
    private let entitlementManager = EntitlementManager()
    private var rewardedAd: RewardedAd?

    #if DEBUG
        /// TEST Id
        private let rewardedId = "ca-app-pub-3940256099942544/1712485313"
    #else
        /// PROD Id
        private let rewardedId = "ca-app-pub-1362150666996278/8022494318"
    #endif

    override init() {
        super.init()
        #if DEBUG
            return
        #endif
        guard entitlementManager.appLaunched >= CharterConstants.minimumAppLaunch else { return }
        loadRewardedAd()
    }

    func loadRewardedAd() {
        Task {
            rewardedAd = try? await RewardedAd.load(with: rewardedId, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func displayRewardedAd() {
        guard let rewardedAd,
              let controller = UIApplication.shared.windows.first?.rootViewController
        else { return }

        rewardedAd.present(from: controller) {
            print("Reward amount: \(rewardedAd.adReward.amount)")
        }
    }

    // MARK: - FullScreenContentDelegate
    func adDidRecordImpression(_: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adDidRecordClick(_: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func ad(_: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError _: Error) {
        print("\(#function) called")
    }

    func adWillPresentFullScreenContent(_: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adWillDismissFullScreenContent(_: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adDidDismissFullScreenContent(_: FullScreenPresentingAd) {
        print("\(#function) called")
        rewardedAd = nil
        loadRewardedAd()
    }
}
