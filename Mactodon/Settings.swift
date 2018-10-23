// Copyright Max von Webel. All Rights Reserved.

import Foundation

struct Settings: Codable {
  struct Account: Codable, CustomDebugStringConvertible {
    let username: String
    let instance: String
    
    init(_ username: String, _ instance: String) {
      self.username = username
      self.instance = instance
    }
    
    var debugDescription: String {
      get {
        return "\(username)@\(instance)"
      }
    }
  }
  var accounts: [Account] = []
  
  private static var shared: Settings?
  
  static func load() -> Settings {
    if let data = UserDefaults.standard.object(forKey: "Settings") as? Data {
      return (try? PropertyListDecoder().decode(Settings.self, from: data)) ?? Settings()
    } else {
      return Settings()
    }
  }
  
  func save() {
    Settings.shared = self
    UserDefaults.standard.set(try! PropertyListEncoder().encode(self), forKey: "Settings")
    UserDefaults.standard.synchronize()
  }
}
