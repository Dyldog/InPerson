//
//  SelectFriendsView.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

struct SelectFriendsItem: Identifiable {
    let id: String
    let name: String
    let enabled: Bool
}

class SelectFriendsViewModel: NSObject, ObservableObject {
    let friendsManager: FriendsManagerType
    let onDone: ([Friend]) -> Void
    
    @Published private var selections: [(Friend, Bool)] = []
    var cellModels: [SelectFriendsItem] {
        selections.map {
            .init(
                id: $0.0.device.id,
                name: $0.0.name,
                enabled: $0.1
            )
        }
    }
    
    init(friendsManager: FriendsManagerType, onDone: @escaping ([Friend]) -> Void) {
        self.friendsManager = friendsManager
        self.onDone = onDone
        super.init()
        self.selections = friendsManager.friends.map { ($0, false) }
    }
    
    func didSelect(item: SelectFriendsItem) {
        guard let idx = selections.firstIndex(where: { $0.0.device.id == item.id }) else { return }
        let selection = selections[idx]
        selections[idx] = (selection.0, !selection.1)
    }
    
    func saveTapped() {
        onDone(selections.filter { $0.1 }.map { $0.0 })
    }
}

struct SelectFriendsView: View {
    @StateObject var viewModel: SelectFriendsViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.cellModels) { item in
                Button {
                    viewModel.didSelect(item: item)
                } label: {
                    HStack {
                        VStack {
                            Text(item.name)
                        }
                        
                        Spacer()
                        
                        if item.enabled {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .toolbar {
            Button("Save") {
                viewModel.saveTapped()
            }
        }
    }
}

struct SelectFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SelectFriendsView(viewModel: .init(
                friendsManager: MockFriendsManager(friends: .mock),
                onDone: { _ in }
            ))
        }
    }
}
