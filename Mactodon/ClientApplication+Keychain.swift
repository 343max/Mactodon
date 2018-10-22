// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Keychain {
  static func set(token: ClientApplication, url: URL) throws {
    try set(service: "Mactodon", account: url.host!, value: token)
  }
  
  static func getToken(url: URL) throws -> ClientApplication? {
    return try get(service: "Mactodon", account: url.host!, type: ClientApplication.self)
  }
}
