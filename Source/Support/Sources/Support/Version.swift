//
//  Version.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation
import UIKit

public enum AppVersionError: Error {
    case errorDecoding
}

public enum Version {

    public static var systemOSVersion = UIDevice.current.systemVersion

    public static var appVersion: String {
        return "\(Bundle.main.version ?? "UNKNOWN")"
    }

    public static func isVersionAbove(minimumVersion: String, version: String) throws -> Bool {
        guard
            let version = splitVersionString(version),
            let minimumVersion = splitVersionString(minimumVersion)
        else {
            throw AppVersionError.errorDecoding
        }
        return minimumVersion.lexicographicallyPrecedes(version) || (minimumVersion == version)
    }
}

// MARK: - Helpers

private extension Version {

    static func splitVersionString(_ versionString: String) -> [Int]? {
        let parts = versionString.components(separatedBy: ".").compactMap { Int($0) }

        guard let major = parts[safe: 0] else {
            return nil
        }

        return [major, parts[safe: 1] ?? 0, parts[safe: 2] ?? 0]
    }
}

private extension Bundle {

    var version: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
