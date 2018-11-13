// Copyright Max von Webel. All Rights Reserved.

import XCTest
@testable import Mactodon

class ValuePromiseTests: XCTestCase {
  func testDidSetValue() {
    let promise = ValuePromise(initialValue: 0)
    var fired = false
    promise.didSet.then {
      XCTAssert($0 == 42)
      fired = true
    }
    
    promise.value = 42
    
    XCTAssert(fired)
  }
  
  func testDidSetValuesMultiple() {
    let promise = ValuePromise(initialValue: "first")
    var fireCount = 0
    promise.didSet.then {
      fireCount += 1
    }
    
    promise.value = "second"
    promise.value = "third"
    
    XCTAssertEqual(2, fireCount)
  }
  
  func testWillSetValue() {
    let promise = ValuePromise(initialValue: 0)
    var fireCount = 0
    promise.willSet.then {
      fireCount += 1
    }
    
    promise.value = 5
    promise.value = 42
    
    XCTAssertEqual(fireCount, 2)
  }
  
  func testDontFireIfValueIsInitial() {
    let promise = ValuePromise(initialValue: 42)
    var wasCalled = false
    promise.didSet.then {
      wasCalled = true
    }
    XCTAssertFalse(wasCalled)
    
    promise.value = 23
    XCTAssertTrue(wasCalled)
  }
  
  func testDoFireIfValueIsntInitial() {
    let promise = ValuePromise(initialValue: 0)
    promise.value = 42
    var wasCalled = false
    promise.didSet.then {
       wasCalled = true
    }
    XCTAssertTrue(wasCalled)
  }
}
