//
//  AppDelegate.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 20/07/2026.
//

import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Demande de permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Permission accordée : \(granted)")
        }

        application.registerForRemoteNotifications()

        return true
    }

    /// Reçoit le token APNs et le transmet à Firebase
    func application(_: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Échec enregistrement notifications : \(error.localizedDescription)")
    }

    /// Notification reçue quand l'app est au premier plan
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent _: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Callback FCM : on récupère le token et on s'abonne au topic
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token : \(fcmToken ?? "nil")")

        Messaging.messaging().subscribe(toTopic: "all_users") { error in
            if let error {
                print("Erreur abonnement topic : \(error.localizedDescription)")
            } else {
                print("Abonné au topic all_users")
            }
        }
        #if DEBUG
            Messaging.messaging().subscribe(toTopic: "debug") { error in
                if let error {
                    print("Erreur abonnement topic : \(error.localizedDescription)")
                } else {
                    print("Abonné au topic debug")
                }
            }
        #endif
    }
}
