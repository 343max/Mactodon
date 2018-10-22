// Copyright Max von Webel. All Rights Reserved.

import Foundation

struct Keychain {
  enum KeychainError: Error {
    case error(status: OSStatus)
  }
  
  static func add(service: String, account: String? = nil, key: Data) throws {
    var query = Keychain.query(withService: service, account: account, accessGroup: nil)
    query[kSecValueData as String] = key
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.error(status: status)
    }
  }
  
  static func get(service: String, account: String? = nil) throws -> Data? {
    var query = Keychain.query(withService: service, account: account, accessGroup: nil)
    query[kSecReturnData as String] = true
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.error(status: status)
    }
    return item as? Data
  }
  
  static func delete(service: String, account: String? = nil) throws {
    let query = Keychain.query(withService: service, account: account, accessGroup: nil)
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.error(status: status)
    }
  }
  
  static func set(service: String, account: String? = nil, key: Data) throws {
    try delete(service: service, account: account)
    try add(service: service, account: account, key: key)
  }
  
  private static func query(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String : Any] {
    var query = [String : AnyObject]()
    query[kSecClass as String] = kSecClassGenericPassword
    query[kSecAttrService as String] = service as AnyObject?
    
    if let account = account {
      query[kSecAttrAccount as String] = account as AnyObject?
    }
    
    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
    }
    
    return query
  }
}

extension Keychain {
  static func add<T>(service: String, account: String? = nil, value: T) throws where T: Encodable {
    let data = try JSONEncoder().encode(value)
    try add(service: service, account: account, key: data)
  }
  
  static func set<T>(service: String, account: String? = nil, value: T) throws where T: Encodable {
    try delete(service: service, account: account)
    try add(service: service, account: account, value: value)
  }
  
  static func get<T>(service: String, account: String? = nil, type: T.Type) throws -> T? where T: Decodable {
    guard let data = try get(service: service, account: account) else {
      return nil
    }
    return try JSONDecoder().decode(type, from: data)
  }
}
