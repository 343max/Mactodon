// Copyright Max von Webel. All Rights Reserved.

import Cocoa

extension NSView {
  var backgroundColor: NSColor? {
    set {
      guard let backgroundColor = backgroundColor else {
        layer?.backgroundColor = nil
        return
      }
      wantsLayer = true
      layer!.backgroundColor = backgroundColor.cgColor
    }
    
    get {
      guard let color = layer?.backgroundColor else {
        return nil
      }
      return NSColor(cgColor: color)
    }
  }
}
