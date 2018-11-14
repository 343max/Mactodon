// Copyright Max von Webel. All Rights Reserved.

import Cocoa

class ProgressIndicatorItem: NSCollectionViewItem, FeedViewCell {
  static var identifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "ProgressIndicatorItem")
  
  func willDisplay() {
    //
  }
  
  func didEndDisplaying() {
    //
  }
  
  override func loadView() {
    view = NSView()
    view.backgroundColor = NSColor.orange
  }
  
  override func viewDidLoad() {
    let spinner = NSProgressIndicator(frame: .zero)
    spinner.style = .spinning
    spinner.sizeToFit()
    spinner.frame = view.bounds.alignedRect(size: spinner.bounds.size, horizontalOffset: 0.5, verticalOffset: 0)
    spinner.autoresizingMask = [.minXMargin, .maxXMargin, .maxYMargin]
    spinner.startAnimation(nil)
    view.addSubview(spinner)
  }
  
  static func size(width: CGFloat) -> CGSize {
    return CGSize(width: width, height: 200)
  }
}
