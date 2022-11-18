//
//  BluetoothCentralManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine
import SwiftyBluetooth

class BluetoothCentralManager {
    
    let serviceUUID: String
    let characteristicUUID: String
    var shouldRetryScanning: Bool = false
    
    @Published var isScanning: Bool = false
    
    @Published private(set) var peripherals: [(device: Device, peripheral: Peripheral)] = []
    var cancellables: Set<AnyCancellable> = .init()
    
    init(service: String, characteristic: String) {
        self.serviceUUID = service
        self.characteristicUUID = characteristic
        
//        SwiftyBluetooth.setSharedCentralInstanceWith(restoreIdentifier: "MY_APP_BLUETOOTH_STATE_RESTORE_IDENTIFIER")
//
//        NotificationCenter.default.addObserver(forName: SwiftyBluetooth.Central.CentralManagerWillRestoreState,
//                                                object: Central.sharedInstance,
//                                                 queue: nil) { (notification) in
//            if let restoredPeripherals = notification.userInfo?["peripherals"] as? [Peripheral] {
//                self.peripherals = restoredPeripherals
//            }
//        }
        
        scanForDevices()
    }
    
    func scanForDevices() {
        guard isScanning == false else { return }
        shouldRetryScanning = true
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: [serviceUUID], timeoutAfter: 20) { scanResult in
            switch scanResult {
            case .scanStarted:
                self.isScanning = true
                self.peripherals = []
            case .scanResult(let peripheral, _, _):
                let deviceID = peripheral.identifier.uuidString
                
                if self.peripherals.contains(where: { $0.device.id == deviceID }) == false {
                    self.peripherals.append((.init(id: deviceID), peripheral))
                }
            case .scanStopped:
                self.isScanning = false
                
                if self.shouldRetryScanning {
                    // Restart the scan
                    self.scanForDevices()
                }
            }
        }
    }
    
    func stopScanning() {
        shouldRetryScanning = false
        SwiftyBluetooth.stopScan()
    }
    
    func connect(to device: Device) -> AnyPublisher<Peripheral, Error> {
        guard let peripheral = peripherals.first(where: { $0.device.id == device.id })?.peripheral else {
            return Fail(error: BluetoothError.cantConnectToUnknownDevice).eraseToAnyPublisher()
        }
        
        return Future<Peripheral, Error> { promise in
            peripheral.connect(withTimeout: nil) { result in
                switch result {
                case .success:
                    promise(.success(peripheral))
                case let .failure(error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func readDataCharacteristic(from peripheral: Peripheral) -> AnyPublisher<Data, Error> {
        Future { promise in
            peripheral.readValue(ofCharacWithUUID: self.characteristicUUID, fromServiceWithUUID: self.serviceUUID) { result in
                switch result {
                case .success(let data):
                    promise(.success(data))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func writeDataCharacteristic(_ value: Data, to peripheralID: UUID) -> AnyPublisher<Void, Error> {
        guard let peripheral = peripherals.first(where: { $0.peripheral.identifier == peripheralID })?.peripheral else {
            return Fail(error: BluetoothError.cantConnectToUnknownDevice).eraseToAnyPublisher()
        }
        
        return Future { promise in
            peripheral.writeValue(ofCharacWithUUID: self.characteristicUUID, fromServiceWithUUID: self.serviceUUID, value: value) { result in
                switch result {
                case .success:
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func disconnect(from device: Device) -> AnyPublisher<Void, Error> {
        guard let peripheral = peripherals.first(where: { $0.device.id == device.id })?.peripheral else {
            return Fail(error: BluetoothError.cantConnectToUnknownDevice).eraseToAnyPublisher()
        }
        
        return Future { promise in
            peripheral.disconnect(completion: { _ in promise(.success(())) })
        }
        .eraseToAnyPublisher()
        
    }
}
