//
//  BluetoothManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine
import CoreBluetooth
import SwiftyBluetooth

/// Represents another user's device
struct Device: Codable, Equatable {
    /// Used to identify the device
    let id: String
}

enum BluetoothError: Error {
    case cantConnectToUnknownDevice
}

/// Handles:
///     - Bluetooth authorisation
///     - Searching for other devices
///     - Alerting when devices come into contact
///     - Sending data via bluetooth to other devices
class BluetoothManager: NSObject, NearbyConnectionManager, DataConnectionManager {
        
    static let serviceUUID = "F28BF684-DCA1-4950-A3E3-3CB0A5CDE8F8"
    static let characteristicUUID = "7F3B6E66-657F-4157-96AD-6358E6015D00"
    
    private let centralManager: BluetoothCentralManager = .init(
        service: BluetoothManager.serviceUUID,
        characteristic: BluetoothManager.characteristicUUID
    )
    private let peripheralManager: BluetoothPeripheralManager = .init(
        service: BluetoothManager.serviceUUID,
        characteristic: BluetoothManager.characteristicUUID
    )
    
    var onInviteHandler: ((String, @escaping (Bool) -> Void) -> Void)?
    var onConnectHandler: ((Device) -> Void)?
    
    var sendDataHandler: (() -> Data)? {
        get { peripheralManager.onRequest }
        set { peripheralManager.onRequest = newValue }
    }
    
    var receiveDataHandler: ((String, Data) -> Void)? {
        get { peripheralManager.onWriteRequest }
        set { peripheralManager.onWriteRequest = newValue }
    }
    
    // MARK: - Public properties
    
    var nearbyDevicesPublisher: CurrentValueSubject<[Device], Never> = CurrentValueSubject([])
    var nearbyDevices: AnyPublisher<[Device], Never> {
        nearbyDevicesPublisher.setFailureType(to: Never.self).eraseToAnyPublisher()
    }
    
    var connectableDevices: AnyPublisher<[Device], Never> { nearbyDevices }
    var scanningPublisher: CurrentValueSubject<Bool, Never> = CurrentValueSubject(false)
    var isScanning: AnyPublisher<Bool, Never> { scanningPublisher.eraseToAnyPublisher() }
    
    var cancellables: Set<AnyCancellable> = .init()
    
    override init() {
        super.init()
        
        centralManager.$isScanning.sink {
            self.scanningPublisher.value = $0
        }
        .store(in: &cancellables)
        
        centralManager.$peripherals.sink { peripherals in
            self.nearbyDevicesPublisher.value = peripherals.map { $0.device }
        }.store(in: &cancellables)
    }
    
    func searchForNearbyDevices() {
        centralManager.scanForDevices()
    }
    
    func initiateConnection(with device: Device) {
        //
    }
    
    func readData(from device: Device) -> AnyPublisher<Data, Error> {
        return centralManager.connect(to: device)
            .flatMap { peripheral in
                self.centralManager.readDataCharacteristic(from: peripheral)
            }
            .flatMap { data in
                self.centralManager.disconnect(from: device).map { data }
            }
            .eraseToAnyPublisher()
    }
    
    func writeData(_ data: Data, to device: Device) -> AnyPublisher<Void, Error> {
        centralManager.stopScanning()
        
        return centralManager.connect(to: device)
            .flatMap { peripheral in
                self.centralManager
                    .writeDataCharacteristic(data, to: UUID(uuidString: device.id)!)
                    .eraseToAnyPublisher()
            }
            .flatMap { _ in
                self.centralManager.disconnect(from: device)
            }
            .flatMap {
                Future { promise in
                    self.searchForNearbyDevices()
                    promise(.success(()))
                }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
