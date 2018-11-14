// Copyright Max von Webel. All Rights Reserved.

import XCTest
@testable import Mactodon

class RelativeDateTests: XCTestCase {

  func testSeconds() {
    let string = TimeInterval(exactly: 32.5)!.relativeString(useSeconds: true)
    XCTAssertEqual(string, "32s")
  }
  
  func testNow() {
    let string = TimeInterval(exactly: 42)!.relativeString(useSeconds: false)
    XCTAssertEqual(string, "now")
  }
  
  func testMinutes() {
    let string = TimeInterval(exactly: 650)!.relativeString(useSeconds: false)
    XCTAssertEqual(string, "10m")
  }

  func testHours() {
    let string = TimeInterval(exactly: 8000)!.relativeString(useSeconds: false)
    XCTAssertEqual(string, "2h")
  }
  
  func testDays() {
    let string = TimeInterval(exactly: 7 * 24 * 3600 + 5000)!.relativeString(useSeconds: false)
    XCTAssertEqual(string, "7d")
  }
}
