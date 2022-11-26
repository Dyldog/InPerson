//
//  SecKey+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import CommonCrypto
import Foundation

extension SecKey {

    func es256Sign(digest: String) -> String {
        guard let message = digest.data(using: .utf8) else {
            fatalError()
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256((message as NSData).bytes, CC_LONG(message.count), &hash)
        let digestData = Data(hash)

        let algorithm = SecKeyAlgorithm.ecdsaSignatureDigestX962SHA256

        guard SecKeyIsAlgorithmSupported(self, .sign, algorithm)
        else {
            fatalError()
        }

        var error: Unmanaged<CFError>?

        guard let signature = SecKeyCreateSignature(self, algorithm, digestData as CFData, &error) else {
            fatalError()
        }

        return (signature as Data).toRawSignature.base64URLEncoded
    }
}
