//
//  inpersonApp.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI

@main
struct inpersonApp: App {

    @StateObject var appModel: AppModel = .init()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationView {
                    EventsList(viewModel: appModel.eventsListModel())
                        .navigationTitle("Events")
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

                NavigationView {
                    FriendsList(viewModel: appModel.friendsListModel())
                        .navigationTitle("Friends")
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }

                NavigationView {
                    DebugView(viewModel: appModel.debugViewModel())
                        .navigationTitle("Debug")
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
            }
            .onAppear {
                appModel.didAppear()
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    var pushToken: String?

    func application(_: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let notification = options?[.remoteNotification] as? [AnyHashable: Any] {
            PushService.shared.received(notification)
        }

        if let a = options?[.remoteNotification] {
            var n = UserDefaults.standard.notification
            let value: String

            if let n = a as? String {
                value = n
            } else if let n = a as? [AnyHashable: Any] {
                value = n.debugDescription
            } else {
                value = "Failed to map"
            }

            n.append(value)
            UserDefaults.standard.notification = n
        }

        PushService.shared.set(
            teamID: Config.teamID,
            cert: Config.cert,
            authKeyID: Config.authKeyID,
            topic: Config.topic
        )

        return true
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        pushToken = token

        PushService.shared.set(token: token)
        PushService.shared.send("HELLO FRIEND", to: token)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

    func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler handler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("Push: \(userInfo)")
        handler(PushService.shared.received(userInfo) ? .newData : .failed)
    }
}
