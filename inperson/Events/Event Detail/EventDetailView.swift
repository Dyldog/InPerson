//
//  EventDetailView.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import SwiftUI
import Combine

extension Attendance {
    var title: String {
        switch self {
        case .going: return "Going"
        case .notGoing: return "Not Going"
        case .maybe: return "Maybe"
        case .host: return "Host"
        }
    }
    
    var emoji: String {
        switch self {
        case .host: return "👑"
        case .going: return "👍"
        case .notGoing: return "👎"
        case .maybe: return "🛟"
        }
    }
    
    var color: Color {
        switch self {
        case .host: return .blue
        case .going: return .green
        case .notGoing: return .red
        case .maybe: return .orange
        }
    }
}

struct ResponderView: View {
    let name: String
    let attendance: Attendance
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            
            Text(attendance.title)
                .foregroundColor(.white)
                .padding(4)
                .background(attendance.color)
                .cornerRadius(10)
        }
        .padding()
    }
}

class EventDetailViewModel: NSObject, ObservableObject, Identifiable {
    let eventManager: EventsManager
    let friendManager: FriendsManager
    
    var id: String { event.id.uuidString }
    let event: Event
    
    @Published var attendance: Attendance?
    private var cancellables: Set<AnyCancellable> = .init()
    
    init(event: Event, friendManager: FriendsManager, eventManager: EventsManager) {
        self.event = event
        self.friendManager = friendManager
        self.eventManager = eventManager
        
        responses = event.responses
        
        super.init()
        
        attendance = responses.first(where: { $0.responderID == userUUID })?.going
        
        $attendance.didSet.sink { [weak self] in
            self?.setUserResponse($0)
        }.store(in: &cancellables)
    }
    
    var title: String { event.title }
    var date: String { event.date.ISO8601Format() }
    private var responses: [Response]
    @Published var responseRows: [(String, Attendance)] = []
    
    private func reloadResponses() {
        responseRows = responses.map {
            (friendManager.friend(for: $0.responderID)?.name ?? $0.responderID, $0.going)
        }
    }
    func setUserResponse(_ response: Attendance?) {
        responses = responses.filter { $0.responderID != userUUID }
        
        if let attendance = attendance {
            responses.insert(.init(responderID: userUUID, going: attendance, lastUpdate: .now), at: 0)
        }
        
        eventManager.updateEvent(event, with: responses)
        
        reloadResponses()
        
        sendEvents()
    }
    
    private func sendEvents() {
        friendManager.shareEventsWithNearbyFriends().sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
    }
    
}

struct EventResponsePicker: View {
    @Binding var selection: Attendance?
    
    var body: some View {
        Picker("Going", selection: $selection) {
            Text("No Response").tag(nil as Attendance?)
            ForEach([Attendance.going, .maybe, .notGoing]) {
                Text("\($0.emoji) \($0.title)" ).tag($0 as Attendance?)
            }
        }
//        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .center) {
                    Text(viewModel.title)
                        .font(.largeTitle)
                    Text(viewModel.date)
                        .font(.largeTitle)
                }
                
                EventResponsePicker(selection: $viewModel.attendance)
                
                VStack {
                    ZStack(alignment: .center) {
                        Rectangle().foregroundColor(.black).frame(maxWidth: .infinity)
                        Text("Responses")
                            .foregroundColor(.white)
                    }
                        
                    
                    ForEach(Array(viewModel.responseRows.enumerated()), id: \.offset) { offset, element in
                        ResponderView(name: element.0, attendance: element.1)
                    }
                }
            }
        }
    }
}
