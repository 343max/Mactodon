// Copyright Max von Webel. All Rights Reserved.

import Cocoa

class AvatarView: NSImageView {
  var clickURL: URL?
  
  enum Sizes {
    case regular
    case small
  }

  static func size(_ size: Sizes) -> CGSize {
    switch size {
    case .regular:
      return CGSize(width: 48, height: 48)
    case .small:
      return CGSize(width: 20, height: 20)
    }
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer!.masksToBounds = true
    backgroundColor = NSColor.textColor.withAlphaComponent(0.1)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layout() {
    super.layout()
    layer?.cornerRadius = min(bounds.height, bounds.width) / 2.0
  }
  
  override func mouseDown(with event: NSEvent) {
    if clickURL != nil {
      alphaValue = 0.6
    }
  }
  
  override func mouseUp(with event: NSEvent) {
    alphaValue = 1.0
    
    if let clickURL = clickURL {
      NSWorkspace.shared.open(clickURL)
    }
  }
}
