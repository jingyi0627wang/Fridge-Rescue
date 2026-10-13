//
//  KeyChainHelper.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import Foundation
import Security


enum KeychainHelper {

    private static let service = "com.freshlings.app"
    private static let account = "password"


    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }


    static func savePassword(_ password: String) {
        SecItemDelete(baseQuery as CFDictionary)

        var newItem = baseQuery
        newItem[kSecValueData as String] = Data(password.utf8)
        SecItemAdd(newItem as CFDictionary, nil)
    }


    static func readPassword() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }


    static func deletePassword() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
