// Copyright Max von Webel. All Rights Reserved.

import Cocoa

struct CellLayout {
  static let margin = NSEdgeInsets(top: 10, left: 5, bottom: 15, right: 15)
  static let columnSpacing = CGFloat(10)
  static let textViewYOffset = CGFloat(3)

  static func textColumn(width: CGFloat) -> CGRect {
    let left = margin.left + AvatarView.size(.regular).width + columnSpacing
    let width = width - left - margin.right
    
    return CGRect(x: left, y: margin.top, width: width, height: 0)
  }
  
  @discardableResult static func layoutActorRow(hasActorRow: Bool, width: CGFloat, avatar: AvatarView, description: NSTextView) -> CGRect {
    if hasActorRow == false {
      avatar.isHidden = true
      description.isHidden = true
      return textColumn(width: width)
    } else {
      avatar.isHidden = false
      description.isHidden = false
      
      var textColumn = self.textColumn(width: width)
      let actorFrame = CGRect(origin: textColumn.origin, size: AvatarView.size(.small))
      avatar.frame = actorFrame
      
      let descriptionLeft: CGFloat = actorFrame.maxX + textViewYOffset
      let descriptionFrame = CGRect(origin: CGPoint(x: descriptionLeft, y: margin.top), size: description.sizeFor(width: width - descriptionLeft - margin.right))
      description.frame = descriptionFrame
      textColumn.origin.y = max(actorFrame.maxY, descriptionFrame.maxY) + 3
      return textColumn
    }
  }
}
