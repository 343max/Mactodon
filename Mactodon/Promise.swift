// Copyright Max von Webel. All Rights Reserved.

import Foundation

protocol UntypedPromise {
  typealias UntypedThenCall = () -> Void
  typealias ErrorCall = (_ error: Error) -> Void
  
  @discardableResult func then(_ completion: @escaping UntypedThenCall) -> Self
  @discardableResult func fail(_ failedCompletion: @escaping ErrorCall) -> Self
  func `throw`(error: Error)
}

class Promise<T> : UntypedPromise {
  typealias ReturnType = T
  typealias CompletionCallback = (_ result: T) -> Void
  typealias ThenCall = (_ result: T) -> Void
  
  public private(set) var error: Error?
  public private(set) var result: T?
  
  var fulfilled: Bool {
    get {
      return result != nil
    }
  }
  
  var failed: Bool {
    get {
      return error != nil
    }
  }
  
  var thenCalls: [ThenCall] = []
  var errorCalls: [ErrorCall] = []
  
  let multiCall: Bool
  
  convenience init(multiCall: Bool = false) {
    self.init({ (_, _) in }, multiCall: multiCall)
  }
  
  convenience init(_ setup: @escaping (_ complete: @escaping CompletionCallback) throws -> Void, multiCall: Bool = false) {
    let fullSetup = { (_ complete: @escaping CompletionCallback, _ promise: Promise) throws -> Void in
      try setup(complete)
    }
    
    self.init(fullSetup, multiCall: multiCall)
  }
  
  init(_ setup: @escaping (_ complete: @escaping CompletionCallback, _ promise: Promise) throws -> Void, multiCall: Bool = false) {
    self.multiCall = multiCall
    do {
      try setup({ (result) in
        self.result = result
        
        self.handle(thens: self.thenCalls)
      }, self)
    } catch {
      self.error = error
      
      self.handle(fails: self.errorCalls)
    }
  }
  
  private func handle(thens: [ThenCall]) {
    guard let result = self.result else {
      return
    }
    
    for thenCall in thens {
      thenCall(result)
    }
  }
  
  private func handle(fails: [ErrorCall]) {
    guard let error = self.error else {
      return
    }
    
    for errorCall in fails {
      errorCall(error)
    }
  }
  
  func `throw`(error: Error) {
    self.error = error
    
    handle(fails: errorCalls)
  }
  
  func fulfill(_ result: T) {
    assert(!fulfilled || multiCall, "promise already fulfilled")
    self.result = result
    handle(thens: thenCalls)
  }
  
  @discardableResult func then(_ completion: @escaping ThenCall) -> Self {
    thenCalls.append(completion)
    handle(thens: [completion])
    return self
  }
  
  @discardableResult func then(_ completion: @escaping UntypedPromise.UntypedThenCall) -> Self {
    self.then { (_) in
      completion()
    }
    
    return self
  }
  
  @discardableResult func fail(_ failedCompletion: @escaping ErrorCall) -> Self {
    errorCalls.append(failedCompletion)
    handle(fails: [failedCompletion])
    return self
  }
  
  func map<U>(_ mapping: @escaping (_ result: T) -> U) -> Promise<U> {
    return Promise<U>({ (completion) in
      self.then({ (result) in
        completion(mapping(result))
      })
    })
  }
}

extension Promise {
  // combines cascading promises into one single promise that fires when the last promise fires
  func combine<T>(_ callback: @escaping (_ result: ReturnType) -> (Promise<T>)) -> Promise<T> {
    return Promise<T>({ [weak self] (finalCallback: @escaping (_: T) -> Void) in
      guard let self = self else {
        return
      }
      
      self.then { (result) in
        callback(result).then {
          finalCallback($0)
        }
      }
    })
  }
}


func allDone<T>(_ promiseContainer: T) -> Promise<T> {
  return Promise<T>({ (completion, allDonePromise) in
    let promises: [UntypedPromise]
    if let dict = promiseContainer as? [AnyHashable: Any] {
      promises = dict.values.compactMap { $0 as? UntypedPromise }
    } else {
      promises = Mirror(reflecting: promiseContainer).children.compactMap { $0.value as? UntypedPromise }
    }
    
    var remaining = promises.count
    for promise in promises {
      promise.then {
        remaining -= 1
        if remaining == 0 {
          completion(promiseContainer)
        }
      }
      
      promise.fail { (error) in
        allDonePromise.throw(error: error)
      }
    }
  })
}
