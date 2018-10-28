// Copyright Max von Webel. All Rights Reserved.

import Atributika
import Cocoa

extension NSAttributedString {
  func sizeFor(width: CGFloat) -> CGSize {
    let textStorage = NSTextStorage(attributedString: self)
    let textContainer = NSTextContainer(containerSize: CGSize(width: width, height: 0))
    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)
    layoutManager.glyphRange(for: textContainer)
    return layoutManager.usedRect(for: textContainer).size
  }
}

extension NSTextView {
  var attributedString: NSAttributedString {
    get {
      return attributedString()
    }
    set {
      let textStorage = self.textStorage!
      let range = NSRange(location: 0, length: textStorage.length)
      textStorage.replaceCharacters(in: range, with: newValue)
    }
  }
  
  func sizeFor(width: CGFloat) -> CGSize {
    return attributedString.sizeFor(width: width)
  }
  
  func set(html: String) {
    self.linkTextAttributes = [
      NSAttributedString.Key.cursor: NSCursor.pointingHand,
    ]
    
    let hrefLinkReplacement = "###"
    let fontSize = NSFont.systemFontSize(for: .regular)
    let allStyle = Style()
      .font(NSFont.systemFont(ofSize: fontSize))
      .foregroundColor(NSColor.labelColor)
    let aStyle = Style("a")
      .foregroundColor(NSColor.controlAccentColor, .normal)
      .link(hrefLinkReplacement)
    let displayName = Style("displayName").font(NSFont.boldSystemFont(ofSize: fontSize)).foregroundColor(NSColor.textColor)
    let at = Style("at").foregroundColor(NSColor.labelColor.withAlphaComponent(0.6))
    attributedString = html
      .style(tags: [displayName, at, aStyle], tuner: { style, tag in
        switch tag.name.lowercased() {
        case "a":
          if style.typedAttributes[.normal]?[.link] as? String == hrefLinkReplacement, let href = tag.attributes["href"] {
            return style.link(href)
          } else {
            return style
          }
        default:
          return style
        }
      })
      .styleAll(allStyle)
      .attributedString
  }
}
