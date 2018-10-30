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

class TootItem: NSCollectionViewItem, FeedViewCell {
  static let identifier = NSUserInterfaceItemIdentifier("TootCollectionViewItem")
  
  private var tootTextView: NSTextView!
  private var creatorName: NSTextView!
  private var creatorAvatar: AvatarView!
  
  private var actionDescription: NSTextView!
  private var actorAvatar: AvatarView!
  
  var model: TootItemModel? {
    didSet {
      guard let model = model else {
        creatorName.attributedString = NSAttributedString(string: "")
        tootTextView.attributedString = NSAttributedString(string: "")
        creatorAvatar.image = nil
        return
      }
      
      let creator = model.creator
      let usernameHtml =
        (creator.displayName != "" ? "<displayName>\(creator.displayName)</displayName> " : "") +
        "<username><a href=\"\(creator.url)\"><at>@</at>\(creator.username)</a></username>"
      
      creatorName.set(html: usernameHtml)
      tootTextView.set(html: model.status.content)
      
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
  
  private func textView() -> NSTextView {
    let textView = NSTextView(frame: .zero)
    textView.isEditable = false
    textView.backgroundColor = NSColor.clear
    textView.isSelectable = true
    return textView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tootTextView = textView()
    view.addSubview(tootTextView)
    
    creatorName = textView()
    view.addSubview(creatorName)
    
    creatorAvatar = AvatarView(frame: .zero)
    view.addSubview(creatorAvatar)
    
    actionDescription = textView()
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
    let textViewSpace: CGFloat = 3

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
      
      let descriptionLeft: CGFloat = actorFrame.maxX + textViewSpace
      let descriptionFrame = CGRect(origin: CGPoint(x: descriptionLeft, y: margin.top), size: actionDescription.sizeFor(width: width - descriptionLeft - margin.right))
      actionDescription.frame = descriptionFrame
      bodyYOffset = max(actorFrame.maxY, descriptionFrame.maxY) + 3
    }
    
    let imageFrame = CGRect(origin: CGPoint(x: margin.left, y: bodyYOffset), size: avatarSize)
    creatorAvatar.frame = imageFrame

    let usernameFrame = CGRect(origin: CGPoint(x: textLeft, y: bodyYOffset), size: creatorName.sizeFor(width: textWidth))
    creatorName.frame = usernameFrame
    
    let tootFrame = CGRect(origin: CGPoint(x: textLeft, y: usernameFrame.maxY + textViewSpace), size: tootTextView.sizeFor(width: textWidth))
    tootTextView.frame = tootFrame
    
    return CGSize(width: width, height: max(tootFrame.maxY, imageFrame.maxY) + margin.bottom)
  }
}

extension TootItem {
  private static var sizingTootItem: TootItem = {
    let item = TootItem(nibName: nil, bundle: nil)
    let _ = item.view
    return item
  }()

  static func size(width: CGFloat, toot: TootItemModel) -> CGSize {
    let item = sizingTootItem
    item.model = toot
    return item.layout(width: width)
  }
}
