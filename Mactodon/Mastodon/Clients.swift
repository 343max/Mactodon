// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Clients {
  internal typealias ClientDict = Dictionary<String, Data>
  internal static let key = "ClientApplications"
  
  static let redirectURI = Bundle.main.bundleIdentifier! + "://authenticated/"
  
  public static func withAppToken(baseURL: URL, _ completion: @escaping (_ result: Result<ClientApplication>) -> ()) {
    if let application = try! Keychain.getAppToken(url: baseURL) {
      completion(.success(application, nil))
    } else {
      let client = Client(baseURL: baseURL.absoluteString)
      let scopes: [AccessScope] = [.read, .write, .follow]
      let request = Clients.register(clientName: "Mactodon", redirectURI: redirectURI, scopes: scopes)
      client.run(request) { (result) in
        if let application = result.value {
          try! Keychain.set(appToken: application, url: baseURL)
        }
        completion(result)
      }
    }
  }
}
