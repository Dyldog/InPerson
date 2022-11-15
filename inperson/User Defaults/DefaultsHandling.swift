//
//  DefaultsHandling.swift
//  Doll
//
//  Created by Dylan Elliott on 5/8/2022.
//

import Foundation

enum DefaultsKey: String, CaseIterable {
    case userPrivateKey = "USER_PRIVATE_KEY"
    case userPublicKey = "USER_PUBLIC_KEY"
    case userCreatedEvents = "USER_CREATED_EVENTS"
    case receivedEvents = "RECEIVED_EVENTS"
    case friends = "FRIENDS"
}

func getFromUserDefaults<T: Codable>(for key: DefaultsKey) -> T? {
    guard let data = SharedDefaults.data(for: key) else { return nil }
    return (try? JSONDecoder().decode(T.self, from: data))
}
    
func saveToUserDefaults<T: Codable>(_ value: T, forKey key: DefaultsKey) {
    guard let data = try? JSONEncoder().encode(value) else { return }
    SharedDefaults.set(data: data, for: key)
    SharedDefaults.synchronize()
}
