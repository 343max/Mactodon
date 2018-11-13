// Copyright Max von Webel. All Rights Reserved.

import Foundation

class ValuePromise<T> {
  var value: T {
    willSet(newValue) {
      willChange.fulfill(newValue)
    }
    didSet {
      didChange.fulfill(value)
    }
  }
  let willChange: Promise<T>
  let didChange: Promise<T>
  
  init(initialValue: T) {
    self.value = initialValue
    self.didChange = Promise(multiCall: true)
    self.willChange = Promise(multiCall: true)
  }
}
