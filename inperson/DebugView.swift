//
//  DebugView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import SwiftUI

struct DebugViewModel {
    let friendsManager: FriendsManager
    let eventsManager: EventsManager
    
    func clear() {
        eventsManager.clearAllData()
        friendsManager.clearAllData()
    }
}

struct DebugView: View {
    @State var viewModel: DebugViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                Button("Clear All Data") {
                    viewModel.clear()
                }
            }
        }
    }
}
