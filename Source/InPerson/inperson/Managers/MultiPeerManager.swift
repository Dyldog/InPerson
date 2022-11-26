//
//  MultiPeerManager.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Combine
import Foundation
import MultiPeer
import MultipeerConnectivity

protocol NearbyConnectionManager {
    var isScanning: AnyPublisher<Bool, Never> { get }
    var nearbyDevices: AnyPublisher<[Device], Never> { get }
    var onConnectHandler: ((Device) -> Void)? { get set }
    var onInviteHandler: ((Device, @escaping (Bool) -> Void) -> Void)? { get set }

    func searchForNearbyDevices()
    func initiateConnection(with device: Device)
}

protocol DataConnectionManager {
    var connectedDevices: AnyPublisher<[Device], Never> { get }
    var receiveDataHandler: ((String, Data) -> Void)? { get set }

    func writeData(_ data: Data, to device: Device) -> AnyPublisher<Void, Error>
}

class MultiPeerManager: NSObject, NearbyConnectionManager, DataConnectionManager {

    enum Constants: String {
        case userUUIDKey = "USER_UUID"
    }

    var scanningPublisher: CurrentValueSubject<Bool, Never> = CurrentValueSubject(false)
    var isScanning: AnyPublisher<Bool, Never> { scanningPublisher.eraseToAnyPublisher() }
    @UserDefaultable(key: .pushToken) private(set) var token: String = ""

    var nearbyPeers: [(Device, MCPeerID)] = [] {
        didSet {
            nearbyDevicesPublisher.value = nearbyPeers.map(\.0)

            connectedDevicesPublisher.value = connectedDevicesPublisher.value.filter { connectedDevice in
                nearbyPeers.contains(where: { $0.0.id == connectedDevice.id })
            }
        }
    }

    var nearbyDevicesPublisher: CurrentValueSubject<[Device], Never> = CurrentValueSubject([])
    var nearbyDevices: AnyPublisher<[Device], Never> {
        nearbyDevicesPublisher.setFailureType(to: Never.self).eraseToAnyPublisher()
    }

    var connectedDevicesPublisher: CurrentValueSubject<[Device], Never> = CurrentValueSubject([])
    var connectedDevices: AnyPublisher<[Device], Never> {
        connectedDevicesPublisher.setFailureType(to: Never.self).eraseToAnyPublisher()
    }

    var onInviteHandler: ((Device, @escaping (Bool) -> Void) -> Void)?
    var onConnectHandler: ((Device) -> Void)?
    var receiveDataHandler: ((String, Data) -> Void)?

    private(set) var peerID: MCPeerID!
    private(set) var session: MCSession!
    private(set) var browser: MCNearbyServiceBrowser!
    private(set) var advertiser: MCNearbyServiceAdvertiser!

    override init() {
        super.init()

        peerID = MCPeerID(displayName: userUUID)
        session = MCSession(peer: peerID)
        session.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "inperson")
        browser.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: [
            Constants.userUUIDKey.rawValue: userUUID,
        ], serviceType: "inperson")
        advertiser.delegate = self

        searchForNearbyDevices()
    }

    func searchForNearbyDevices() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()

        scanningPublisher.value = true
    }

    private func device(with id: String) -> Device? {
        nearbyDevicesPublisher.value.first(where: { $0.id == id })
    }

    func initiateConnection(with device: Device) {
        guard let peer = nearbyPeers.first(where: { $0.0.id == device.id }) else {
            DebugManager.shared.logEvent(.notSendingInviteToUnknownPeer(device: device.id))
            return
        }
        browser.invitePeer(peer.1, to: session, withContext: try! Device(id: userUUID, pushToken: token).encode(), timeout: 0)

        DebugManager.shared.logEvent(.sentInvite(device: device.id))
    }

    func writeData(_ data: Data, to device: Device) -> AnyPublisher<Void, Error> {
        guard let peer = nearbyPeers.first(where: { $0.0.id == device.id }) else {
            return Fail(error: BluetoothError.cantConnectToUnknownDevice).eraseToAnyPublisher()
        }

        DebugManager.shared.logEvent(.sentDataToDevice(device: device.id, data: data.debugString))

        do {
            try session.send(data, toPeers: [peer.1], with: .reliable)

            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            print("Error sending data: \(error.localizedDescription)")

            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}

extension MultiPeerManager: MCSessionDelegate {
    func session(_: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard let peerIdx = nearbyPeers.firstIndex(where: { $0.1 == peerID }) else { return }

        let peer = nearbyPeers[peerIdx]

        if state == .connected {
            DebugManager.shared.logEvent(.connectedToDevice(device: "\(peerID.displayName)/\(peer.0)"))
            connectedDevicesPublisher.value = connectedDevicesPublisher.value.filter { $0.id != peer.0.id } + [
                peer.0,
            ]
            onConnectHandler?(peer.0)
        } else if state == .notConnected {
            DebugManager.shared.logEvent(.disconnectedFromDevice(device: "\(peerID.displayName)/\(peer.0.id)"))
            connectedDevicesPublisher.value = connectedDevicesPublisher.value.filter { $0.id != peer.0.id }

            if let device = device(with: peer.0.id) {
                initiateConnection(with: device)
            }
        }
    }

    func session(_: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let peer = nearbyPeers.first(where: { $0.1 == peerID }) else { return }
        DebugManager.shared.logEvent(.receivedDataFromDevice(device: peer.0.id, data: data.debugString))
        receiveDataHandler?(peer.0.id, data)
    }

    func session(
        _: MCSession,
        didReceive _: InputStream,
        withName _: String,
        fromPeer _: MCPeerID
    ) {
        //
    }

    func session(
        _: MCSession, didStartReceivingResourceWithName _: String,
        fromPeer _: MCPeerID, with _: Progress
    ) {
        //
    }

    func session(
        _: MCSession,
        didFinishReceivingResourceWithName _: String,
        fromPeer _: MCPeerID,
        at _: URL?, withError _: Error?
    ) {
        //
    }
}

extension MultiPeerManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(
        _: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard
            let peer = nearbyPeers.first(where: { $0.1 == peerID }),
            let device: Device = try? context?.decoded(as: Device.self)
        else {
            DebugManager.shared.logEvent(.ignoredInviteFromUnknownPeer(device: peerID.displayName))
            return invitationHandler(false, nil)
        }

        DebugManager.shared.logEvent(.receivedInvite(device: device))

        onInviteHandler?(device, { invitationHandler($0, self.session) })
    }
}

extension MultiPeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error)
    }

    func browser(_: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let appID = info?[Constants.userUUIDKey.rawValue] else { return }
        DebugManager.shared.logEvent(.foundPeer(id: "\(peerID.displayName)/\(appID)"))
        nearbyPeers = nearbyPeers.filter { $0.0.id != appID } + [(.init(id: userUUID, pushToken: "NO TOKEN"), peerID)]
    }

    func browser(_: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DebugManager.shared.logEvent(.lostPeer(id: peerID.displayName))
        nearbyPeers = nearbyPeers.filter { $0.1 != peerID }
    }
}

extension UIApplication {
    func showAlert(_ alert: UIAlertController) {
        windows.first?.rootViewController?.present(alert, animated: true)
    }
}
