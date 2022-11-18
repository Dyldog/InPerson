//
//  inpersonApp.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI

class AppModel: NSObject, ObservableObject {
    let nearbyManager: NearbyConnectionManager
    let dataManager: DataConnectionManager
    let friendsManager: FriendsManager
    let cryptoManager: CryptoManager
    let eventsManager: EventsManager
    
    override init() {
        let multipeerManager = MultiPeerManager()
        self.nearbyManager = multipeerManager
        self.dataManager = multipeerManager
        self.cryptoManager = CryptoManager()
        self.eventsManager = EventsManager()
        
        self.friendsManager = .init(
            dataManager: self.dataManager,
            cryptoManager: self.cryptoManager,
            eventsManager: self.eventsManager,
            nearbyManager: self.nearbyManager
        )
    }
    func didAppear() {
        
    }
    
    func eventsListModel() -> EventsListViewModel {
        return .init(
            friendsManager: friendsManager,
            eventsManager: eventsManager,
            nearbyManager: nearbyManager
        )
    }
    
    func friendsListModel() -> FriendsListViewModel {
        return .init(
            friendsManager: friendsManager,
            nearbyManager: nearbyManager
        )
    }
    
    func debugViewModel() -> DebugViewModel {
        return .init(
            friendsManager: friendsManager,
            eventsManager: eventsManager
        )
    }
}

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
