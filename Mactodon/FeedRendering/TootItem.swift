// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

class TootItem: NSCollectionViewItem {
  static let identifier = NSUserInterfaceItemIdentifier("TootCollectionViewItem")
  
  private var usernameField: NSTextField!
  private var tootField: NSTextField!
  private var avatarView: AvatarView!
  var status: Status? {
    didSet {
      guard let status = status else {
        usernameField.attributedStringValue = NSAttributedString(string: "")
        tootField.attributedStringValue = NSAttributedString(string: "")
        avatarView.image = nil
        return
      }
      
      let usernameHtml =
        (status.account.displayName != "" ? "<displayName>\(status.account.displayName)</displayName> " : "") +
        "<username><a href=\"\(status.account.url)\"><at>@</at>\(status.account.username)</a></username>"
      
      usernameField.set(html: usernameHtml)
      tootField.set(html: status.content)
    }
  }
  
  private class FlippedView: NSView {
    override var isFlipped: Bool {
      get {
        return true
      }
    }
  }
  
  override func loadView() {
    view = FlippedView()
  }
  
  private func textField() -> NSTextField {
    let field = NSTextField(frame: .zero)
    field.isEditable = false
    field.isBordered = false
    field.backgroundColor = NSColor.clear
    field.isSelectable = true
    field.allowsEditingTextAttributes = true
    return field
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tootField = textField()
    view.addSubview(tootField)
    
    usernameField = textField()
    usernameField.cell?.lineBreakMode = .byTruncatingTail
    view.addSubview(usernameField)
    
    avatarView = AvatarView(frame: .zero)
    view.addSubview(avatarView)
  }
  
  func willDisplay() {
    guard let status = status else {
      return
    }
    
    Nuke.loadImage(with: URL(string: status.account.avatar + "&username=\(status.account.username)")!, into: avatarView)
    avatarView.clickURL = URL(string: status.account.url)
  }
  
  func didEndDisplaying() {
    Nuke.cancelRequest(for: avatarView)
  }
  
  override func viewDidLayout() {
    super.viewDidLayout()
    
    layout(width: collectionView!.bounds.width)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    status = nil
  }
  
  @discardableResult func layout(width: CGFloat) -> NSSize {
    let inset = NSEdgeInsets(top: 10, left: 5, bottom: 15, right: 15)
    let avatarSize = AvatarView.size(.regular)
    let avatarSpace: CGFloat = 10
    let textFieldSpace: CGFloat = 3
    
    let imageFrame = CGRect(origin: CGPoint(x: inset.left, y: inset.top), size: avatarSize)
    avatarView.frame = imageFrame
    
    let textLeft = imageFrame.maxX + avatarSpace
    let textWidth = width - textLeft - inset.right
    
    let textfieldSize = CGSize(width: textWidth, height: 0)
    let usernameFrame = CGRect(origin: CGPoint(x: textLeft, y: inset.top), size: usernameField.sizeThatFits(textfieldSize))
    usernameField.frame = usernameFrame
    
    let tootFrame = CGRect(origin: CGPoint(x: textLeft, y: usernameFrame.maxY + textFieldSpace), size: tootField.sizeThatFits(textfieldSize))
    tootField.frame = tootFrame
    
    return CGSize(width: width, height: max(tootFrame.maxY, imageFrame.maxY) + inset.bottom)
  }
}
