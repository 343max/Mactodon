// Copyright Max von Webel. All Rights Reserved.

import Cocoa

extension NSTextView {
  func prepareAsLabel() {
    isEditable = false
    backgroundColor = NSColor.clear
    isSelectable = true
  }
}
