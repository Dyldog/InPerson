//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine

struct FriendListItem: Identifiable {
    let name: String?
    let id: String
    var isFriend: Bool { name != nil }
}

class FriendsListViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager
    let nearbyManager: NearbyConnectionManager
    
    @Published private var nearbyDevices: [Device] = []
    @Published var nearbyPeople: [FriendListItem] = []
    @Published var otherFriends: [FriendListItem] = []
    
    @Published var isScanning: Bool = false
    
    var cancellables: Set<AnyCancellable> = .init()
    
    init(friendsManager: FriendsManager, nearbyManager: NearbyConnectionManager) {
        self.friendsManager = friendsManager
        self.nearbyManager = nearbyManager
        
        super.init()
        
        nearbyManager.isScanning.sink {
            self.isScanning = $0
        }.store(in: &cancellables)
        
        nearbyManager.nearbyDevices.didSet.receive(on: RunLoop.main).sink { peripherals in
            self.nearbyDevices = peripherals
            self.reload()
        }
        .store(in: &cancellables)
        
        friendsManager.$friends.didSet.sink { friends in
            self.reload()
        }
        .store(in: &cancellables)
        
        nearbyManager.searchForNearbyDevices()
        
        reload()
    }
    
    private func reload() {
        nearbyPeople = nearbyDevices.map {
            .init(name: self.friendsManager.friend(for: $0.id)?.name, id: $0.id)
        }
        
        otherFriends = friendsManager.friends.filter { friend in
            nearbyDevices.contains(where: { $0.id == friend.device.id }) == false
        }.map {
            .init(name: $0.name, id: $0.device.id)
        }
    }
    
    func addFriend(_ uuid: String) {
        guard friendsManager.friend(for: uuid) == nil else { return }
//        friendsManager.addFriend(for: uuid, with: name, and: device)
        
        nearbyManager.initiateConnection(with: .init(id: uuid))
        reload()
    }
    
    func searchTapped() {
        nearbyManager.searchForNearbyDevices()
    }
}

struct FriendListItemView: View {
    let item: FriendListItem
    let addTapped: () -> Void
    
    var body: some View {
        HStack {
            if let name = item.name {
                VStack(alignment: .leading) {
                    Text(name)
                    Text(item.id)
                        .font(.footnote)
                }
            } else {
                Text(item.id)
            }
            
            Spacer()
            if item.isFriend == false {
                Button("Add Friend") {
                    addTapped()
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
    }
}
struct FriendsList: View {
    @StateObject var viewModel: FriendsListViewModel
    @State var addDialogID: String?
    @State var showingAddDialog: Bool = false
    
    var body: some View {
        List {
            Section("Nearby") {
                ForEach(viewModel.nearbyPeople) { row in
                    FriendListItemView(item: row) {
                        viewModel.addFriend(row.id)
                    }
                }
            }
            
            Section("Other Friends") {
                ForEach(viewModel.otherFriends) { row in
                    FriendListItemView(item: row) {
                        addDialogID = row.id
                        showingAddDialog = true
                    }
                }
            }
        }
        .toolbar {
            Button {
                viewModel.searchTapped()
            } label: {
                Circle().foregroundColor(viewModel.isScanning ? .green : .red)
            }
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}
