// Copyright Max von Webel. All Rights Reserved.

import Foundation

extension CGRect {
  func alignedRect(size: CGSize, horizontalOffset: Float, verticalOffset: Float) -> CGRect {
    return CGRect(origin: CGPoint(x: round((width - size.width) * CGFloat(horizontalOffset)),
                                  y: round((height - size.height) * CGFloat(verticalOffset))),
                  size: size)
  }
}
