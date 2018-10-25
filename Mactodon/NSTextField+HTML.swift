// Copyright Max von Webel. All Rights Reserved.

import Atributika
import Cocoa

extension NSTextField {
  func set(html: String) {
    let hrefLinkReplacement = "###"
    let fontSize = NSFont.systemFontSize(for: .regular)
    let allStyle = Style()
      .font(NSFont.systemFont(ofSize: fontSize))
      .foregroundColor(NSColor.labelColor)
    let aStyle = Style("a")
      .foregroundColor(NSColor.linkColor, .normal)
      .link(hrefLinkReplacement)
    let displayName = Style("displayName").font(NSFont.boldSystemFont(ofSize: fontSize)).foregroundColor(NSColor.textColor)
    let at = Style("at").foregroundColor(NSColor.labelColor.withAlphaComponent(0.6))
    attributedStringValue = html
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
