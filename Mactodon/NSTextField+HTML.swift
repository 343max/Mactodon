// Copyright Max von Webel. All Rights Reserved.

import Atributika
import Cocoa

extension NSTextField {
  func set(html: String) {
    let allStyle = Style().font(NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))).foregroundColor(NSColor.labelColor)
    let aStyle = Style("a").foregroundColor(NSColor.linkColor)
    attributedStringValue = html.style(tags: aStyle).styleAll(allStyle).attributedString
  }
}
