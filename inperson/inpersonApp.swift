//
//  inpersonApp.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI

@main
struct inpersonApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationView {
                    EventsList()
                        .navigationTitle("Events")
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                
                NavigationView {
                    FriendsList()
                        .navigationTitle("Friends")
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                
                NavigationView {
                    DebugView()
                        .navigationTitle("Debug")
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
            }
            .onAppear {
                BluetoothManager.shared.scanForDevices()
                _ = FriendsManager.shared
            }
        }
    }
}
