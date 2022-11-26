//
//  FriendsListItem.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI

struct FriendListItem: Identifiable {
    let name: String?
    let id: String
    let lastSeen: String?
    var isFriend: Bool { name != nil }
}

struct FriendListItemView: View {
    let item: FriendListItem
    let addTapped: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let name = item.name {
                    Text(name)
                    Text(item.id)
                        .font(.footnote)
                } else {
                    Text(item.id)
                }

                if let lastSeen = item.lastSeen {
                    Text(lastSeen).font(.footnote)
                }
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
