// Copyright Max von Webel. All Rights Reserved.

import Foundation

extension Promise where T: Any {
  var mainQueue: Promise<T> {
    get {
      let promise = Promise<T>(multiCall: self.multiCall)
      self.then { (result: T) in
        DispatchQueue.main.async {
          promise.fulfill(result)
        }
      }
      self.fail { (error) in
        DispatchQueue.main.async {
          promise.throw(error: error)
        }
      }
      return promise
    }
  }
}
