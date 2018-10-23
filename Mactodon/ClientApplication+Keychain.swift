// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Keychain {
  static func set(appToken: ClientApplication, url: URL) throws {
    try set(service: "Mactodon", account: url.host!, value: appToken)
  }
  
  static func getAppToken(url: URL) throws -> ClientApplication? {
    return try get(service: "Mactodon", account: url.host!, type: ClientApplication.self)
  }
}
