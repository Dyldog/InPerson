//
//  Data+Extensions.swift
//  Eventful
//
//  Created by Harry Singh on 17/11/2022.
//  Copyright © 2022 HazDyl. All rights reserved.
//

import CommonCrypto
import Foundation

extension Data {

    var base64URLEncoded: String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    var toECKeyData: Data {
        let (result, _) = toASN1Element

        guard
            case let ASN1Element.seq(elements: es) = result,
            case let ASN1Element.bytes(data: privateOctest) = es[2]
        else {
            fatalError()
        }

        let (octest, _) = privateOctest.toASN1Element
        guard
            case let ASN1Element.seq(elements: seq) = octest,
            case let ASN1Element.bytes(data: privateKeyData) = seq[1],
            case let ASN1Element.constructed(tag: _, elem: publicElement) = seq[3],
            case let ASN1Element.bytes(data: publicKeyData) = publicElement
        else {
            fatalError()
        }

        let keyData = (publicKeyData.drop(while: { $0 == 0x00 }) + privateKeyData)
        return keyData
    }

    var toPrivateKey: SecKey {
        var error: Unmanaged<CFError>?

        guard
            let privateKey =
            SecKeyCreateWithData(
                self as CFData,
                [
                    kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                    kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                    kSecAttrKeySizeInBits: 256,
                ] as CFDictionary,
                &error
            )
        else {
            fatalError()
        }
        return privateKey
    }

    /// Convert an ASN.1 format EC signature returned by commoncrypto into a raw 64bit signature
    var toRawSignature: Data {
        let (result, _) = toASN1Element

        guard
            case let ASN1Element.seq(elements: es) = result,
            case let ASN1Element.bytes(data: sigR) = es[0],
            case let ASN1Element.bytes(data: sigS) = es[1]
        else {
            fatalError()
        }

        let rawSig = sigR.dropLeadingBytes() + sigS.dropLeadingBytes()
        return rawSig
    }
}

private extension Data {

    indirect enum ASN1Element {
        case seq(elements: [ASN1Element])
        case integer(int: Int)
        case bytes(data: Data)
        case constructed(tag: Int, elem: ASN1Element)
        case unknown
    }

    var toASN1Element: (ASN1Element, Int) {
        guard count >= 2 else {
            // format error
            return (.unknown, self.count)
        }

        switch self[0] {
        case 0x30: // sequence
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            var result: [ASN1Element] = []
            var subdata = self.advanced(by: 1 + lengthOfLength)
            var alreadyRead = 0

            while alreadyRead < length {
                let (e, l) = subdata.toASN1Element
                result.append(e)
                subdata = subdata.count > l ? subdata.advanced(by: l) : Data()
                alreadyRead += l
            }
            return (.seq(elements: result), 1 + lengthOfLength + length)

        case 0x02: // integer
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            if length < 8 {
                var result: Int = 0
                let subdata = self.advanced(by: 1 + lengthOfLength)
                // ignore negative case
                for i in 0 ..< length {
                    result = 256 * result + Int(subdata[i])
                }
                return (.integer(int: result), 1 + lengthOfLength + length)
            }
            // number is too large to fit in Int; return the bytes
            return (.bytes(data: self.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))), 1 + lengthOfLength + length)

        case let s where (s & 0xE0) == 0xA0: // constructed
            let tag = Int(s & 0x1F)
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            let subdata = self.advanced(by: 1 + lengthOfLength)
            let (e, _) = subdata.toASN1Element
            return (.constructed(tag: tag, elem: e), 1 + lengthOfLength + length)

        default: // octet string
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            return (.bytes(data: self.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))), 1 + lengthOfLength + length)
        }
    }

    // SecKeyCreateSignature seems to sometimes return a leading zero; strip it out
    func dropLeadingBytes() -> Data {
        if count == 33 {
            return dropFirst()
        }
        return self
    }

    func readLength() -> (Int, Int) {
        if self[0] & 0x80 == 0x00 { // short form
            return (Int(self[0]), 1)
        } else {
            let lenghOfLength = Int(self[0] & 0x7F)
            var result: Int = 0
            for i in 1 ..< (1 + lenghOfLength) {
                result = 256 * result + Int(self[i])
            }
            return (result, 1 + lenghOfLength)
        }
    }
}
