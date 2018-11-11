// Copyright Max von Webel. All Rights Reserved.

import Cocoa

class FlippedView: NSView {
  override var isFlipped: Bool {
    get {
      return true
    }
  }
}
