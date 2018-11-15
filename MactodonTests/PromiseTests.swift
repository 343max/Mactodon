// Copyright Max von Webel. All Rights Reserved.

import XCTest
@testable import Mactodon

class PromiseTests: XCTestCase {
  
  func testPromise() {
    var setupCalled = false
    var thenCalled = false
    
    let promise = Promise<String>({ (completion) in
      setupCalled = true
      completion("hello")
    }).then { (result) in
      thenCalled = true
      XCTAssertEqual(result, "hello")
    }
    
    XCTAssertTrue(promise.fulfilled)
    XCTAssertTrue(setupCalled)
    XCTAssertTrue(thenCalled)
  }
  
  func testDelayedResponse() {
    let expectation = XCTestExpectation()
    
    let promise = Promise<String>({ (completion) in
      DispatchQueue.main.async {
        completion("later")
      }
    }).then { (result) in
      XCTAssertEqual(result, "later")
      expectation.fulfill()
    }
    
    XCTAssertFalse(promise.fulfilled)
    
    wait(for: [expectation], timeout: 0.1)
  }
  
  func testFailure() {
    var setupCalled = false
    var failureCalled = false
    var thenCalled = false
    
    struct SomeError: Error {
      let message: String
    }
    
    let promise = Promise<String>({ (completion) in
      setupCalled = true
      throw SomeError(message: "message")
    }).then { (_) in
      thenCalled = true
      }.fail { (error) in
        guard let error = error as? SomeError else {
          return
        }
        
        XCTAssertEqual(error.message, "message")
        failureCalled = true
    }
    
    XCTAssertTrue(promise.failed)
    
    XCTAssertTrue(setupCalled)
    XCTAssertTrue(failureCalled)
    XCTAssertFalse(thenCalled)
  }
  
  func testArrayPromise() {
    var completionCalled = false
    var promise1setup = false
    var promise1complete = false
    var promise2setup = false
    var promise2complete = false
    
    allDone([
      Promise<Int>({ (completion) in
        promise1setup = true
        completion(42)
      }).then { promise1complete = true },
      Promise<String>({ (completion) in
        promise2setup = true
        completion("world")
      }).then{ promise2complete = true }
      ]).then { completionCalled = true }
    
    XCTAssertTrue(promise1setup)
    XCTAssertTrue(promise1complete)
    XCTAssertTrue(promise2setup)
    XCTAssertTrue(promise2complete)
    XCTAssertTrue(completionCalled)
  }
  
  func testStructPromise() {
    var completionCalled = false
    
    struct TestStruct {
      let name: Promise<String>
      let age: Promise<Int>
    }
    
    let myStruct = TestStruct(name: Promise({ (completion) in
      completion("max")
    }), age: Promise({ (completion) in
      completion(39)
    }))
    
    let promise: Promise<TestStruct> = allDone(myStruct)
    promise.then { (_) in completionCalled = true }
    
    XCTAssertTrue(completionCalled)
    XCTAssertEqual(myStruct.name.result!, "max")
    XCTAssertEqual(myStruct.age.result!, 39)
  }
  
  func testClassPromise() {
    var completionCalled = false
    
    class TestClass {
      let name: Promise<String>
      let age: Promise<Int>
      
      init(name: Promise<String>, age: Promise<Int>) {
        self.name = name
        self.age = age
      }
    }
    
    let myStruct = TestClass(name: Promise({ (completion) in
      completion("max")
    }), age: Promise({ (completion) in
      completion(39)
    }))
    
    let promise: Promise<TestClass> = allDone(myStruct)
    promise.then { (_) in completionCalled = true }
    
    XCTAssertTrue(completionCalled)
    XCTAssertEqual(myStruct.name.result!, "max")
    XCTAssertEqual(myStruct.age.result!, 39)
  }
  
  func testStructPromiseFailure() {
    var completionCalled = false
    var failureCalled = false
    
    struct LottoNumberPredictionError: Error { }
    
    let guranteedLottoNumbers = [
      Promise<Int>({ (_) in
        throw LottoNumberPredictionError()
      }),
      
      Promise<Int>({ (completion) in
        completion(42)
      })
    ]
    
    allDone(guranteedLottoNumbers).then {
      completionCalled = true
      }.fail { (_) in
        failureCalled = true
    }
    
    XCTAssertFalse(completionCalled)
    XCTAssertTrue(failureCalled)
  }
  
  func testDictPromise() {
    var completionCalled = false
    
    enum Key {
      case name
      case age
    }
    
    let dict: [Key: Promise<Any>] = [
      Key.name: Promise<Any>({ (completion) in
        completion("Max")
      }),
      Key.age: Promise<Any>({ (completion) in
        completion(39)
      })
    ]
    
    allDone(dict).then { (dict) in
      XCTAssertEqual(dict[Key.name]?.result as! String, "Max")
      XCTAssertEqual(dict[Key.age]?.result as! Int, 39)
      completionCalled = true
    }
    
    XCTAssertTrue(completionCalled)
  }
  
  func testAsyncDictPromise() {
    let expectation = XCTestExpectation()
    
    enum Key {
      case name
      case age
    }
    
    let dict: [Key: Promise<Any>] = [
      Key.name: Promise<Any>({ (completion) in
        DispatchQueue.main.async {
          completion("Max")
        }
      }),
      Key.age: Promise<Any>({ (completion) in
        DispatchQueue.main.async {
          completion(39)
        }
      })
    ]
    
    allDone(dict).then { (dict) in
      XCTAssertEqual(dict[Key.name]?.result as! String, "Max")
      XCTAssertEqual(dict[Key.age]?.result as! Int, 39)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1)
  }
  
  func testMapping() {
    var finalThenCalled = false
    Promise<Int>({ (completion) in
      completion(42)
    }).map({ (x) -> String in
      return "the answer: \(x)"
    }).then { (string) in
      XCTAssertEqual("the answer: 42", string)
      finalThenCalled = true
    }
    XCTAssertTrue(finalThenCalled)
  }
  
  func testCombinig() {
    /*
     Combine two dependend promisses into one combined promisses that fires when both dependent promise have fired.
     Even when the inner promise was only created when the outer promise fired
     */
    let outerPromise = Promise<Int>()
    var innerPromise: Promise<String>? = nil
    
    let combinedPromise: Promise<String> = outerPromise.combine { (number) -> (Promise<String>) in
      innerPromise = Promise<String>({ (completion) in
        completion("number: \(number)")
      })
      return innerPromise!
    }
   
    combinedPromise.then {
      XCTAssertEqual($0, "number: 42")
    }

    XCTAssertNil(innerPromise)
    XCTAssertFalse(outerPromise.fulfilled)
    XCTAssertFalse(combinedPromise.fulfilled)
    
    outerPromise.fulfill(42)
    
    XCTAssertTrue(combinedPromise.fulfilled)
    XCTAssertTrue(innerPromise?.fulfilled ?? false)
    XCTAssertTrue(outerPromise.fulfilled)
  }
  
  func testMultiCallSingleFire() {
    let promise = Promise<Int>(multiCall: true)
    var countA = 0
    var countB = 0
    promise.then {
      countA += 1
    }
    promise.fulfill(42)
    promise.then {
      countB += 1
    }
    
    XCTAssertEqual(countA, 1)
    XCTAssertEqual(countB, 1)
  }
}
