//
//  EventDetailView.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Combine
import Foundation
import SwiftUI

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                VStack(alignment: .center) {
                    Text(viewModel.title)
                        .font(.largeTitle)
                    Text(viewModel.date)
                        .font(.headline)
                    Text(viewModel.event.publicity.title)
                        .font(.headline)
                        .padding(.bottom, 10)

                    if !viewModel.isMyEvent {
                        EventResponsePicker(selection: $viewModel.attendance)
                    } else {
                        Text("This is your event")
                    }

                    if viewModel.canInvite {
                        Button("Invite") {
                            viewModel.inviteTapped()
                        }
                    }
                }
                .padding()

                VStack {
                    ZStack(alignment: .center) {
                        Rectangle().foregroundColor(.black).frame(maxWidth: .infinity)
                        Text("Responses")
                            .foregroundColor(.white)
                    }

                    ForEach(Array(viewModel.responseRows.enumerated()), id: \.offset) { _, element in
                        ResponderView(name: element.0, response: element.1)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showInviteView) {
            NavigationView {
                SelectFriendsView(viewModel: viewModel.inviteViewModel())
                    .navigationTitle("Invite Friends")
            }
        }
    }
}
