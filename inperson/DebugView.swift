//
//  DebugView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import SwiftUI

struct DebugView: View {
    var body: some View {
        ScrollView {
            VStack {
                Button("Clear All Data") {
                    EventsManager.shared.clearAllData()
                    FriendsManager.shared.clearAllData()
                }
            }
        }
    }
}
