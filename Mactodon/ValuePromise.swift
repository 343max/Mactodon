// Copyright Max von Webel. All Rights Reserved.

import Foundation

class ValuePromise<T> {
  var value: T {
    willSet(newValue) {
      willSet.fulfill(newValue)
    }
    didSet {
      didSet.fulfill(value)
    }
  }
  let willSet: Promise<T>
  let didSet: Promise<T>
  
  init(initialValue: T) {
    self.value = initialValue
    self.didSet = Promise(multiCall: true)
    self.willSet = Promise(multiCall: true)
  }
}
