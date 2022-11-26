//
//  EventDetailViewModel.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Combine
import Foundation

class EventDetailViewModel: NSObject, ObservableObject, Identifiable {
    let eventManager: EventsManager
    let friendManager: FriendsManager

    var id: String { event.id.uuidString }
    private(set) var event: Event

    @Published var attendance: Attendance?
    private var cancellables: Set<AnyCancellable> = .init()

    var title: String { event.title }
    var date: String { event.date.ISO8601Format() }
    var isMyEvent: Bool {
        event.creatorID == userUUID
    }

    var canInvite: Bool {
        switch event.publicity {
        case .private:
            return isMyEvent
        case .canInvite, .autoShare: return true
        }
    }

    private var responses: [Response]
    @Published var responseRows: [(String, ResponseStatus)] = []

    @Published var showInviteView: Bool = false

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

    private func hasResponded(_ invite: Invite) -> Bool {
        responses.contains(where: { $0.responderID == invite.recipientID })
    }

    private func reloadResponses() {
        var rows: [(String, ResponseStatus)] = []
        var remainingResponses = responses

        remainingResponses.removeAll(where: { $0.responderID == userUUID })

        if isMyEvent {
            rows += [("Me", .host)]
        } else if event.invites.contains(where: { $0.recipientID == userUUID }) {
            rows += [
                (friendManager.friend(for: event.creatorID)?.name ?? event.creatorID, .attendance(.host)),
                ("Me", attendance.map { .attendance($0) } ?? .invited),
            ]
        } else {
            rows += [
                (friendManager.friend(for: event.creatorID)?.name ?? event.creatorID, .attendance(.host)),
                ("Me", attendance.map { .attendance($0) } ?? .notResponded),
            ]
        }

        rows += remainingResponses.map {
            (friendManager.friend(for: $0.responderID)?.name ?? $0.responderID, .attendance($0.going))
        }

        rows += event.invites.filter { $0.recipientID != event.creatorID && $0.recipientID != userUUID && hasResponded($0) == false }.map {
            (friendManager.friend(for: $0.recipientID)?.name ?? $0.recipientID, .invited)
        }

        responseRows = rows
    }

    func setUserResponse(_: Attendance?) {
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

    func inviteTapped() {
        showInviteView = true
    }

    func inviteViewModel() -> SelectFriendsViewModel {
        .init(friendsManager: friendManager) { [weak self] in
            guard let self = self else { return }
            self.event = self.eventManager.inviteFriends($0, to: self.event) ?? self.event
            self.reloadResponses()
            self.showInviteView = false
        }
    }
}
