// Copyright Max von Webel. All Rights Reserved.

import Cocoa

class FollowingItem: NSCollectionViewItem, FeedViewCell {
  static let identifier = NSUserInterfaceItemIdentifier("FollowingItem")
  
  func willDisplay() {
    //
  }
  
  func didEndDisplaying() {
    //
  }
  
  override func loadView() {
    view = NSView()
    view.wantsLayer = true
    view.layer!.backgroundColor = NSColor.orange.cgColor
  }
  
  static func size(width: CGFloat) -> CGSize {
    return CGSize(width: width, height: 20)
  }
}
