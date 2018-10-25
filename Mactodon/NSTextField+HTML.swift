// Copyright Max von Webel. All Rights Reserved.

import Atributika
import Cocoa

extension NSTextField {
  func set(html: String) {
    let fontSize = NSFont.systemFontSize(for: .regular)
    let allStyle = Style().font(NSFont.systemFont(ofSize: fontSize)).foregroundColor(NSColor.labelColor)
    let aStyle = Style("a").foregroundColor(NSColor.linkColor)
    let displayName = Style("displayName").font(NSFont.boldSystemFont(ofSize: fontSize)).foregroundColor(NSColor.textColor)
    let at = Style("at").foregroundColor(NSColor.labelColor.withAlphaComponent(0.6))
    attributedStringValue = html.style(tags: [aStyle, displayName, at]).styleAll(allStyle).attributedString
  }
}
