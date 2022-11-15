//
//  BluetoothManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import Combine

/// Represents another user's device
struct Device: Codable, Equatable {
    /// Used to identify the device
    let macAddress: String
}

enum BluetoothError: Error {
    
}

/// Handles:
///     - Bluetooth authorisation
///     - Searching for other devices
///     - Alerting when devices come into contact
///     - Sending data via bluetooth to other devices
class BluetoothManager {
    
    let nearbyDevicesPublisher: AnyPublisher<[Device], Never> = Just([]).eraseToAnyPublisher()
    let receivedDataPublisher: AnyPublisher<(Data, Device), Never> = PassthroughSubject().eraseToAnyPublisher()
    
    func requestAuthorisationIfNeeded() -> AnyPublisher<Void, BluetoothError> {
        Just(())
            .setFailureType(to: BluetoothError.self)
            .eraseToAnyPublisher()
    }
    
    func searchForDevices() -> AnyPublisher<[Device], BluetoothError> {
        return Just([])
            .setFailureType(to: BluetoothError.self)
            .eraseToAnyPublisher()
    }
    
    func send(_ data: Data, to device: Device) -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
