//
//  MultiPeerManager.swift
//  inperson
//
//  Created by Dylan Elliott on 18/11/2022.
//

import Foundation
import Combine
import MultiPeer
import MultipeerConnectivity

protocol NearbyConnectionManager {
    var isScanning: AnyPublisher<Bool, Never> { get }
    var nearbyDevices: AnyPublisher<[Device], Never> { get }
    func searchForNearbyDevices()
    func initiateConnection(with device: Device)
}

protocol DataConnectionManager {
    var connectableDevices: AnyPublisher<[Device], Never> { get }
    
    var onInviteHandler: ((String, @escaping (Bool) -> Void) -> Void)? { get set }
    var onConnectHandler: ((Device) -> Void)? { get set }
    var receiveDataHandler: ((String, Data) -> Void)? { get set }
    func writeData(_ data: Data, to device: Device) -> AnyPublisher<Void, Error>
}

class MultiPeerManager: NSObject, NearbyConnectionManager, DataConnectionManager {
    
    enum Constants: String {
        case userUUIDKey = "USER_UUID"
    }
    
    var scanningPublisher: CurrentValueSubject<Bool, Never> = CurrentValueSubject(false)
    var isScanning: AnyPublisher<Bool, Never> { scanningPublisher.eraseToAnyPublisher() }
    
    var nearbyPeers: [(String, MCPeerID)] = [] {
        didSet {
            nearbyDevicesPublisher.value = nearbyPeers.map {
                .init(id: $0.0)
            }
        }
    }
    var nearbyDevicesPublisher: CurrentValueSubject<[Device], Never> = CurrentValueSubject([])
    var nearbyDevices: AnyPublisher<[Device], Never> {
        nearbyDevicesPublisher.setFailureType(to: Never.self).eraseToAnyPublisher()
    }
    
    var connectableDevicesPublisher: CurrentValueSubject<[Device], Never> = CurrentValueSubject([])
    var connectableDevices: AnyPublisher<[Device], Never> {
        connectableDevicesPublisher.setFailureType(to: Never.self).eraseToAnyPublisher()
    }
    
    var onInviteHandler: ((String, @escaping (Bool) -> Void) -> Void)?
    var onConnectHandler: ((Device) -> Void)?
    var receiveDataHandler: ((String, Data) -> Void)?
        
    private(set) var peerID: MCPeerID!
    private(set) var session: MCSession!
    private(set) var browser: MCNearbyServiceBrowser!
    private(set) var advertiser: MCNearbyServiceAdvertiser!
    
    override init() {
        super.init()
        
        self.peerID = MCPeerID(displayName: userUUID)
        self.session = MCSession(peer: self.peerID)
        self.session.delegate = self
        self.browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: "inperson")
        self.browser.delegate = self
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: [
            Constants.userUUIDKey.rawValue: userUUID
        ], serviceType: "inperson")
        self.advertiser.delegate = self
    }
    
    func searchForNearbyDevices() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        
        scanningPublisher.value = true
    }
    
    func initiateConnection(with device: Device) {
        guard let peer = nearbyPeers.first(where: { $0.0 == device.id }) else { return }
        browser.invitePeer(peer.1, to: session, withContext: nil, timeout: 0)
    }
    
    func writeData(_ data: Data, to device: Device) -> AnyPublisher<Void, Error> {
        guard let peer = nearbyPeers.first(where: { $0.0 == device.id }) else {
            return Fail(error: BluetoothError.cantConnectToUnknownDevice).eraseToAnyPublisher()
        }
        
        do {
            try session.send(data, toPeers: [peer.1], with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
        
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension MultiPeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard let peerIdx = nearbyPeers.firstIndex(where: { $0.1 == peerID }) else { return }
        
        let peer = nearbyPeers[peerIdx]
        
        if state == .connected {
            connectableDevicesPublisher.value = connectableDevicesPublisher.value.filter { $0.id != peer.0 } + [
                .init(id: peer.0)
            ]
            onConnectHandler?(.init(id: peer.0))
        } else {
            connectableDevicesPublisher.value = connectableDevicesPublisher.value.filter { $0.id != peer.0 }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let peer = nearbyPeers.first(where: { $0.1 == peerID }) else { return }
        receiveDataHandler?(peer.0, data)
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        //
    }
    
    func session(
        _ session: MCSession, didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID, with progress: Progress
    ) {
        //
    }
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?, withError error: Error?
    ) {
        //
    }
    
    
}

extension MultiPeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let peer = nearbyPeers.first(where: { $0.1 == peerID }) else {
            return invitationHandler(false, nil)
        }
        onInviteHandler?(peer.0, { invitationHandler($0, self.session) })
    }
}

extension MultiPeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let appID = info?[Constants.userUUIDKey.rawValue] else { return }
        nearbyPeers = nearbyPeers.filter { $0.0 != appID } + [(appID, peerID)]
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        nearbyPeers = nearbyPeers.filter { $0.1 != peerID }
    }
}

extension UIApplication {
    func showAlert(_ alert: UIAlertController) {
//        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Invitation Received"
//
//        let ac = UIAlertController(title: appName, message: "'\(peerID.displayName)' wants to connect.", preferredStyle: .alert)
//        let declineAction = UIAlertAction(title: "Decline", style: .cancel) { [weak self] _ in
//            invitationHandler(false, self?.session)
//        }
//        let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
//            invitationHandler(true, self?.session)
//        }
//
//        ac.addAction(declineAction)
//        ac.addAction(acceptAction)
        
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
}
