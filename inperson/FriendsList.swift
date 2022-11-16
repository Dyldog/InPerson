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
    let id: UUID
    var isFriend: Bool { name != nil }
}

class FriendsListViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManager = .shared
    let bluetoothManager: BluetoothManager = .shared
    
    @Published var nearbyDevices: [FriendListItem] = []
    @Published var otherFriends: [FriendListItem] = []
    
    @Published var isScanning: Bool = false
    
    var cancellables: Set<AnyCancellable> = .init()
    
    override init() {
        super.init()
        
        bluetoothManager.$isScanning.sink {
            self.isScanning = $0
        }
        .store(in: &cancellables)
        
        bluetoothManager.$devices.receive(on: RunLoop.main).sink { peripherals in
            self.reload()
        }
        .store(in: &cancellables)
        
        bluetoothManager.scanForDevices()
        
        reload()
    }
    
    private func reload() {
        nearbyDevices = self.bluetoothManager.devices.map {
            .init(name: self.friendsManager.friend(for: $0.id)?.name, id: $0.id)
        }
        
        otherFriends = friendsManager.friends.filter { friend in
            nearbyDevices.contains(where: { $0.id == friend.device.id }) == false
        }.map {
            .init(name: $0.name, id: $0.device.id)
        }
    }
    
    func addFriend(_ uuid: UUID, name: String, device: Device) {
        guard friendsManager.friend(for: uuid) == nil else { return }
        friendsManager.addFriend(for: uuid, with: name, and: device)
        reload()
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
                    Text(item.id.uuidString)
                        .font(.footnote)
                }
            } else {
                Text(item.id.uuidString)
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
    @StateObject var viewModel: FriendsListViewModel = .init()
    @State var addDialogID: UUID?
    @State var showingAddDialog: Bool = false
    
    var body: some View {
        List {
            Section("Nearby") {
                ForEach(viewModel.nearbyDevices) { row in
                    FriendListItemView(item: row) {
                        addDialogID = row.id
                        showingAddDialog = true
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
        .alert(isPresented: $showingAddDialog, TextAlert(title: "What's their name?", action: {
            guard let addDialogID = addDialogID, let name = $0 else { return }
            viewModel.addFriend(addDialogID, name: name, device: .init(id: addDialogID))
        }))
        .toolbar {
            Button {
                BluetoothManager.shared.scanForDevices()
            } label: {
                Circle().foregroundColor(viewModel.isScanning ? .green : .red)
            }
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}
