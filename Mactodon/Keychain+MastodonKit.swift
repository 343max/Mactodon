// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Keychain {
  private static let appName = "Mactodon"
  static func set(clientApplication: ClientApplication, instance: String) throws {
    try set(service: appName, account: instance, value: clientApplication)
  }
  
  static func getClientApplication(instance: String) throws -> ClientApplication? {
    return try get(service: appName, account: instance, type: ClientApplication.self)
  }
}

extension Keychain {
  private static func full(username: String, _ instance: String) -> String {
    return "\(username)@\(instance)"
  }
  
  static func set(loginSettings: LoginSettings, forUser username: String, instance: String) throws {
    try set(service: appName, account: full(username: username, instance), value: loginSettings)
  }
  
  static func getLoginSettings(forUser username: String, instance: String) throws -> LoginSettings? {
    return try get(service: appName, account: full(username: username, instance), type: LoginSettings.self)
  }
}
