// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit
import p2_OAuth2

extension OAuth2CodeGrant {
  convenience init(baseURL: URL, application: ClientApplication) {
    let scopes: [AccessScope] = [.read, .write, .follow]
    self.init(settings: [
      "client_id": application.clientID,
      "client_secret": application.clientSecret,
      "authorize_uri": "\(baseURL.absoluteString)oauth/authorize",
      "token_uri": "\(baseURL.absoluteString)oauth/token",
      "redirect_uris": [application.redirectURI],
      "scope": scopes.map({ $0.rawValue }).joined(separator: " "),
      ])
  }
}
