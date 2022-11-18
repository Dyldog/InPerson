//
//  ContentView.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import SwiftUI
import Combine

var userUUID: String = UIDevice.current.identifierForVendor?.uuidString ?? "ERROR!!!"

struct EventsList: View {
    @StateObject var viewModel: EventsListViewModel
    @State var showAddEvent: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section("Mine") {
                    ForEach(viewModel.myEvents) { event in
                        Button {
                            viewModel.eventTapped(event)
                        } label: {
                            EventListItemView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button("Add Event") {
                        showAddEvent = true
                    }
                }
                
                Section("Others'") {
                    ForEach(viewModel.othersEvents) { event in
                        Button {
                            viewModel.eventTapped(event)
                        } label: {
                            EventListItemView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if !viewModel.pastEvents.isEmpty {
                    Section("Past") {
                        ForEach(viewModel.pastEvents) { event in
                            EventListItemView(event: event)
                        }
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
        .sheet(isPresented: $showAddEvent) {
            AddEventsView() {
                viewModel.addEvent(title: $0.0, date: $0.1)
                showAddEvent = false
            }
        }
        .sheet(item: $viewModel.detailViewModel) { viewModel in
            EventDetailView(viewModel: viewModel)
        }
    }
}
