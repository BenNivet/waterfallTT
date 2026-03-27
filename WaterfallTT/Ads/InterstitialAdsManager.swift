//
//  InterstitialAdsManager.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 24/09/2025.
//

import FirebaseAnalytics
import Foundation
import GoogleMobileAds

@MainActor
class InterstitialAdsManager: NSObject, ObservableObject {
    @Published var interstitialAdLoaded = false
    private let entitlementManager = EntitlementManager()
    var interstitialAd: InterstitialAd?

    #if DEBUG
        /// TEST Id
        private let interstitialId = "ca-app-pub-3940256099942544/4411468910"
    #else
        /// PROD Id
        private let interstitialId = "ca-app-pub-1362150666996278/9064336024"
    #endif

    override init() {
        super.init()
        #if DEBUG
            return
        #endif
        guard entitlementManager.appLaunched >= CharterConstants.minimumAppLaunch else { return }
        loadInterstitialAd()
    }

    func loadInterstitialAd() {
        Task {
            do {
                let ad = try await InterstitialAd.load(with: interstitialId, request: Request())
                print("🟢: Loading succeeded")
                interstitialAd = ad
                interstitialAd?.fullScreenContentDelegate = self
                interstitialAdLoaded = true
            } catch {
                print("🔴: \(error.localizedDescription)")
                interstitialAdLoaded = false
                return
            }
        }
    }

    func displayInterstitialAd() {
        guard let interstitialAd,
              let root = UIApplication.shared.windows.first?.rootViewController
        else { return }

        interstitialAd.present(from: root)
        self.interstitialAd = nil
    }
}

// MARK: - FullScreenContentDelegate
extension InterstitialAdsManager: FullScreenContentDelegate {
    func ad(_: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError _: Error) {
        print("🟡: Failed to display interstitial ad")
        loadInterstitialAd()
    }

    func adWillPresentFullScreenContent(_: FullScreenPresentingAd) {
        print("🤩: Displayed an interstitial ad")
        self.interstitialAd = nil
    }

    func adDidDismissFullScreenContent(_: FullScreenPresentingAd) {
        print("😔: Interstitial ad closed")
    }
}
