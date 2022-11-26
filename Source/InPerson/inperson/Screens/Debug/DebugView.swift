//
//  DebugView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Combine
import Foundation
import SwiftUI

struct DebugView: View {
    @StateObject var viewModel: DebugViewModel

    var body: some View {
        List {
            Section {
                Button("Clear All Data") {
                    viewModel.clear()
                }

                Button("Send Events") {
                    viewModel.forceSendEvents()
                }
            }
            Section {
                ForEach(viewModel.debugEvents, id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(item.timestamp.ISO8601Format())
                            .font(.footnote).foregroundColor(.gray)
                        Text(item.event.string)
                            .font(.body)
                    }
                }
            }
        }
    }
}
