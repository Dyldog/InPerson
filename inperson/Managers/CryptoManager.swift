//
//  CryptoManager.swift
//  inperson
//
//  Created by Dylan Elliott on 15/11/2022.
//

import Foundation

/// Handles:
///     - Generating app's public/private keys
///     - Making app's public key available
///     - Encrypting data (i.e: with app's private key)
///     - Decrypting data (i.e: with a given friend's public key)
class CryptoManager {
        
    @UserDefaultable(key: .userPrivateKey) private var userPrivateKey: String! = nil
    @UserDefaultable(key: .userPublicKey) private(set) var userPublicKey: String! = nil
    
    init() {
        if userPublicKey == nil || userPrivateKey == nil {
            generateUserKeyPair()
        }
    }
    
    private func generateUserKeyPair() {
        userPrivateKey = "PRIVATE_KEY"
        userPublicKey = "PUBLIC_KEY"
    }
    
    func encryptData(_ data: Data) -> Data {
        return data
    }
    
    func decryptData(_ data: Data, using key: String) -> Data {
        return data
    }
}
