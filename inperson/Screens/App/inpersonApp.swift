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
