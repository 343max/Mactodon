// Copyright Max von Webel. All Rights Reserved.

import Cocoa

protocol FeedViewCell {
  static var identifier: NSUserInterfaceItemIdentifier { get }
  func willDisplay()
  func didEndDisplaying()
}
