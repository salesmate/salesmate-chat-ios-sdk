//
//  DataPersistency.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 18/08/21.
//

import Foundation

protocol Storage: AnyObject {
    var pseudoName: String? { get set}
    var socketAuthToken: String? { get set}
}

// TODO: We are currently saving in UserDefaults as plain text. We should either save in keychain or save encrypted data.
class UserDefaultStorage: Storage {

    static let userDefaultKey = "com.salesmate.chat"
    static let pseudoNameKey = "pseudoName.com.salesmate.chat"
    static let socketAuthTokenKey = "socketAuthTokenKey.com.salesmate.chat"

    private let standard: UserDefaults = UserDefaults.standard

    var pseudoName: String? {
        get {
            guard let data = standard.value(forKey: Self.userDefaultKey) as? [String: String] else { return nil }
            return data[Self.pseudoNameKey]
        }
        set {
            var data: [String: String] = (standard.object(forKey: Self.userDefaultKey) as? [String: String]) ?? [:]
            data[Self.pseudoNameKey] = newValue
            standard.setValue(data, forKey: Self.userDefaultKey)
        }
    }

    var socketAuthToken: String? {
        get {
            guard let data = standard.value(forKey: Self.userDefaultKey) as? [String: String] else { return nil }
            return data[Self.socketAuthTokenKey]
        }
        set {
            var data: [String: String] = (standard.object(forKey: Self.userDefaultKey) as? [String: String]) ?? [:]
            data[Self.socketAuthTokenKey] = newValue
            standard.setValue(data, forKey: Self.userDefaultKey)
        }
    }
}
