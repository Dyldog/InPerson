//
//  PushRequest.swift
//  Eventful
//
//  Created by Harry Singh on 22/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import Foundation

struct PushRequest: RequestType {

    struct Header: Encodable {
        let alg: String = "ES256"
        let kid: String
    }

    struct Claims: Encodable {
        let iss: String
        let iat: TimeInterval = Date.now.timeIntervalSince1970
    }

    struct Body<T: Codable>: Codable {
        struct Alert: Codable {
            enum CodingKeys: String, CodingKey {
                case contentAvailable = "content-available"
            }

            let contentAvailable: Int = 1
        }

        var aps: Alert = .init()
        let message: T
    }

    #if DEBUG
        let baseURL: String = "https:api.sandbox.push.apple.com"
    #else
        let baseURL: String = "https:api.sandbox.push.apple.com"
    #endif

    let method: HTTPMethod = .post
    let path: String
    let headers: [String: String]
    let body: Encodable?

    init<T: Codable>(
        teamID: String,
        cert: String,
        authKeyID: String,
        topic: String,
        token: String,
        body: T
    ) {
        path = "/3/device/\(token)"
        let jwtHeader: String = try! Header(kid: authKeyID).encode().base64URLEncoded
        let jwtClaims: String = try! Claims(iss: teamID).encode().base64URLEncoded
        let jwtHeaderClaims: String = "\(jwtHeader).\(jwtClaims)"
        let authToken: String = "\(jwtHeaderClaims).\(cert.toASN1.toECKeyData.toPrivateKey.es256Sign(digest: jwtHeaderClaims))"

        headers = [
            "authorization": "bearer \(authToken)",
            "apns-topic": topic,
            "apns-priority": "5",
            "apns-push-type": "background",
        ]
        self.body = Body<T>(message: body)
    }
}
