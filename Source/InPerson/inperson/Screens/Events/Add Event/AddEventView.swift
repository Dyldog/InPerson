//
//  AddEventView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import SwiftUI

struct EventCreationDetails {
    let title: String
    let date: Date
    let publicity: EventPublicity
    let invitees: [Friend]
}

class AddEventsViewModel: NSObject, ObservableObject {

    private let friendsManager: FriendsManager
    @Published var showAddFriends: Bool = false

    @Published var title: String = ""
    @Published var date: Date = .now
    @Published var publicity: EventPublicity = .private
    @Published var invitees: [Friend] = []
    var inviteesDescription: String {
        if invitees.isEmpty {
            return "Select"
        } else {
            return "\(invitees.count) invited"
        }
    }

    private let onDone: (EventCreationDetails) -> Void

    init(friendsManager: FriendsManager, onDone: @escaping (EventCreationDetails) -> Void) {
        self.friendsManager = friendsManager
        self.onDone = onDone
        super.init()
    }

    func selectFriendsViewModel() -> SelectFriendsViewModel {
        .init(friendsManager: friendsManager) { [weak self] friends in
            self?.invitees = friends
            self?.showAddFriends = false
        }
    }

    func inviteTapped() {
        showAddFriends = true
    }

    func saveTapped() {
        onDone(.init(title: title, date: date, publicity: publicity, invitees: invitees))
    }
}

struct AddEventsView: View {
    @StateObject var viewModel: AddEventsViewModel

    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $viewModel.title, prompt: Text("Title")).font(.largeTitle)
                    .padding(.top, 20)

                DatePicker("Date", selection: $viewModel.date).font(.largeTitle)

                Picker("Publicity", selection: $viewModel.publicity) {
                    ForEach(EventPublicity.allCases, id: \.rawValue) {
                        Text($0.title).tag($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 10)

                Text(viewModel.publicity.description)
                    .font(.footnote).foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                HStack {
                    Text("Invitations").font(.largeTitle)
                    Spacer()
                    Button(viewModel.inviteesDescription) {
                        viewModel.inviteTapped()
                    }
                }
                .padding(.top, 2)

                Button("Add") {
                    viewModel.saveTapped()
                }
                .font(.largeTitle)
                .padding(.top, 40)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Event")
            .sheet(isPresented: $viewModel.showAddFriends) {
                NavigationView {
                    SelectFriendsView(viewModel: viewModel.selectFriendsViewModel())
                        .navigationTitle("Invite Friends")
                }
            }
        }
    }
}
