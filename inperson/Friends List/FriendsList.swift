//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine

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
