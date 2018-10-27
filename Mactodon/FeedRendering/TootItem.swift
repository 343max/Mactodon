// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

struct TootItemModel {
  let kind: Kind
  let status: Status
  let creator: Account
  
  enum Kind {
    case post
    case boost(booster: Account)
  }
  
  init(status: Status) {
    if let reblog = status.reblog {
      self.status = reblog
      self.creator = reblog.account
      self.kind = .boost(booster: status.account)
    } else {
      self.status = status
      self.creator = status.account
      self.kind = .post
    }
  }
}

extension TootItemModel {
  struct Action {
    let actor: Account
    let descriptionHtml: String
  }
  
  var action: Action? {
    get {
      switch self.kind {
      case .post:
        return nil
      case .boost(let booster):
        let html = "\(booster.displayName != "" ? booster.displayName : booster.username) boosted"
        return Action(actor: booster, descriptionHtml: html)
      }
    }
  }
}

class TootItem: NSCollectionViewItem {
  static let identifier = NSUserInterfaceItemIdentifier("TootCollectionViewItem")
  
  private var tootField: NSTextField!
  private var creatorName: NSTextField!
  private var creatorAvatar: AvatarView!
  
  private var actionDescription: NSTextField!
  private var actorAvatar: AvatarView!
  
  var model: TootItemModel? {
    didSet {
      guard let model = model else {
        creatorName.attributedStringValue = NSAttributedString(string: "")
        tootField.attributedStringValue = NSAttributedString(string: "")
        creatorAvatar.image = nil
        return
      }
      
      let creator = model.creator
      let usernameHtml =
        (creator.displayName != "" ? "<displayName>\(creator.displayName)</displayName> " : "") +
        "<username><a href=\"\(creator.url)\"><at>@</at>\(creator.username)</a></username>"
      
      creatorName.set(html: usernameHtml)
      tootField.set(html: model.status.content)
      
      actionDescription.set(html: model.action?.descriptionHtml ?? "")
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
    
    creatorName = textField()
    creatorName.cell?.lineBreakMode = .byTruncatingTail
    view.addSubview(creatorName)
    
    creatorAvatar = AvatarView(frame: .zero)
    view.addSubview(creatorAvatar)
    
    actionDescription = textField()
    view.addSubview(actionDescription)
    
    actorAvatar = AvatarView(frame: .zero)
    view.addSubview(actorAvatar)
  }
  
  func willDisplay() {
    guard let model = model else {
      return
    }
    
    Nuke.loadImage(with: URL(string: model.creator.avatar)!, into: creatorAvatar)
    creatorAvatar.clickURL = URL(string: model.creator.url)
    
    if let actor = model.action?.actor {
      Nuke.loadImage(with: URL(string: actor.avatar)!, into: actorAvatar)
      actorAvatar.clickURL = URL(string: actor.url)
    }
  }
  
  func didEndDisplaying() {
    Nuke.cancelRequest(for: creatorAvatar)
  }
  
  override func viewDidLayout() {
    super.viewDidLayout()
    
    layout(width: collectionView!.bounds.width)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    model = nil
  }
  
  @discardableResult func layout(width: CGFloat) -> NSSize {
    let margin = NSEdgeInsets(top: 10, left: 5, bottom: 15, right: 15)
    let avatarSize = AvatarView.size(.regular)
    let avatarSpace: CGFloat = 10
    let textFieldSpace: CGFloat = 3

    let textLeft = margin.left + avatarSize.width + avatarSpace
    let textWidth = width - textLeft - margin.right

    let bodyYOffset: CGFloat
    if model?.action == nil {
      actorAvatar.isHidden = true
      actionDescription.isHidden = true
      bodyYOffset = margin.top
    } else {
      actorAvatar.isHidden = false
      actionDescription.isHidden = false
      
      let actorFrame = CGRect(origin: CGPoint(x: textLeft, y: margin.top), size: AvatarView.size(.small))
      actorAvatar.frame = actorFrame
      
      let descriptionLeft: CGFloat = actorFrame.maxX + textFieldSpace
      let descriptionSize = actionDescription.sizeThatFits(CGSize(width: width - descriptionLeft - margin.right, height: 0))
      let descriptionFrame = CGRect(origin: CGPoint(x: descriptionLeft, y: margin.top), size: descriptionSize)
      actionDescription.frame = descriptionFrame
      bodyYOffset = max(actorFrame.maxY, descriptionFrame.maxY) + 3
    }
    
    let imageFrame = CGRect(origin: CGPoint(x: margin.left, y: bodyYOffset), size: avatarSize)
    creatorAvatar.frame = imageFrame

    let textfieldSize = CGSize(width: textWidth, height: 0)
    let usernameFrame = CGRect(origin: CGPoint(x: textLeft, y: bodyYOffset), size: creatorName.sizeThatFits(textfieldSize))
    creatorName.frame = usernameFrame
    
    let tootFrame = CGRect(origin: CGPoint(x: textLeft, y: usernameFrame.maxY + textFieldSpace), size: tootField.sizeThatFits(textfieldSize))
    tootField.frame = tootFrame
    
    return CGSize(width: width, height: max(tootFrame.maxY, imageFrame.maxY) + margin.bottom)
  }
}
