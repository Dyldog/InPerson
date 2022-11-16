//
//  BluetoothPeripheralManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation
import CoreBluetooth

class BluetoothPeripheralManager: NSObject {
    
    static let userIDAdvertisementKey = CBAdvertisementDataLocalNameKey
    
    let serviceUUID: String
    let characteristicUUID: String
    
    private var peripheralManager : CBPeripheralManager!
    
    var onRequest: (() -> Data)?
    var onWriteRequest: ((UUID, Data) -> Void)?
    @UserDefaultable(key: .userUUID) var advertisementID: UUID = .init()
    
    init(service: String, characteristic: String) {
        self.serviceUUID = service
        self.characteristicUUID = characteristic
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private var service: CBUUID!
    
    func addServices() {
        // 1. Create instance of CBMutableCharcateristic
        let characteristic = CBMutableCharacteristic(
            type: CBUUID(string: BluetoothManager.characteristicUUID),
            properties: [.notify, .write, .read],
            value: nil,
            permissions: [.readable, .writeable]
        )

        service = CBUUID(string: BluetoothManager.serviceUUID)
        
        let myService = CBMutableService(type: service, primary: true)
        myService.characteristics = [characteristic]
        
        peripheralManager.add(myService)
        
        startAdvertising()
    }
    
    func startAdvertising() {
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey : advertisementID.uuidString,
            CBAdvertisementDataServiceUUIDsKey : [service],
        ])
        print("Started Advertising")
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
        case .resetting:
            print("Bluetooth Device is RESETTING")
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            addServices()
        @unknown default:
            print("Unknown State")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = onRequest?()
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        requests.forEach {
            if let data = $0.value, let id = $0.characteristic.service?.peripheral?.identifier {
                onWriteRequest?(id, data)
            }
        }
    }
    
    
    
    
}
