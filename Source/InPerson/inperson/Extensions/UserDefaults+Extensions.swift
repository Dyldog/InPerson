//
//  UserDefaults+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 22/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

public extension UserDefaults {

    @objc var requests: [Data] {
        get {
            return object(forKey: "requests") as? [Data] ?? []
        }
        set {
            set(newValue, forKey: "requests")
        }
    }

    @objc var notifications: [Data] {
        get {
            return object(forKey: "notifications") as? [Data] ?? []
        }
        set {
            set(newValue, forKey: "notifications")
        }
    }

    @objc var notification: [String] {
        get {
            return stringArray(forKey: "notification") ?? []
        }
        set {
            set(newValue, forKey: "notification")
        }
    }

    @objc var devices: [Data] {
        get {
            return object(forKey: "devices") as? [Data] ?? []
        }
        set {
            set(newValue, forKey: "devices")
        }
    }
}
