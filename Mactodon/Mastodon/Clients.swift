// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Clients {
  internal typealias ClientDict = Dictionary<String, Data>
  internal static let key = "ClientApplications"
  
  public static func storedClient(baseURL: URL) -> ClientApplication? {
    guard let dict = UserDefaults.standard.dictionary(forKey: key) as? ClientDict else {
      return nil
    }
    
    guard let data = dict[baseURL.absoluteString] else {
      return nil
    }
    return try? PropertyListDecoder().decode(ClientApplication.self, from: data)
  }
  
  public static func store(baseURL: URL, application: ClientApplication?) {
    let defaults = UserDefaults.standard
    
    var dict = defaults.dictionary(forKey: key) as? ClientDict ?? [:]
    if let application = application {
      do {
        dict[baseURL.absoluteString] = try PropertyListEncoder().encode(application)
      } catch {
        return
      }
    } else {
      dict.removeValue(forKey: baseURL.absoluteString)
    }
    defaults.set(dict, forKey: key)
    defaults.synchronize()
  }
  
  public static func withApplication(baseURL: URL, _ completion: @escaping (_ result: Result<ClientApplication>) -> ()) {
    if let application = storedClient(baseURL: baseURL) {
      completion(.success(application, nil))
    } else {
      let client = Client(baseURL: baseURL.absoluteString)
      let scopes: [AccessScope] = [.read, .write, .follow]
      let request = Clients.register(clientName: "Mactodon", redirectURI: "mactodon://authorize", scopes: scopes)
      client.run(request) { (result) in
        if let application = result.value {
          store(baseURL: baseURL, application: application)
        }
        completion(result)
      }
    }
  }
}
