// Copyright Max von Webel. All Rights Reserved.

import Foundation

extension URLComponents {
  init?(string: String, queryItems: [String: String]) {
    self.init(string: string)
    self.queryItems = queryItems.compactMap({ (name, value) -> URLQueryItem in
      return URLQueryItem(name: name, value: value)
    })
  }
}

extension URLComponents {
  var queryDict: Dictionary<String, String?> {
    get {
      return queryItems?.reduce(into: Dictionary<String, String?>(), { (dict, item) in
        dict[item.name] = item.value
      }) ?? [:]
    }
  }
}
