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
    var isFriend: Bool { name != nil }
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
