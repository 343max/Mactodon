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
    case mention(account: Account)
    case favourite(account: Account)
  }
}

extension TootItemModel {
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
  init?(notification: MastodonKit.Notification) {
    switch notification.type {
    case .follow:
      return nil
    case .mention:
      self.kind = .mention(account: notification.account)
    case .reblog:
      self.kind = .boost(booster: notification.account)
    case .favourite:
      self.kind = .favourite(account: notification.account)
    }
    self.status = notification.status!
    self.creator = self.status.account
  }
}

extension Account {
  var someDisplayName: String {
    get {
      return displayName != "" ? displayName : username
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
        let html = "\(booster.someDisplayName) boosted"
        return Action(actor: booster, descriptionHtml: html)
      case .favourite(let account):
        let html = "\(account.someDisplayName) favourited"
        return Action(actor: account, descriptionHtml: html)
      case .mention(_):
        return nil
      }
    }
  }
}

class TootItem: NSCollectionViewItem, FeedViewCell {
  static let identifier = NSUserInterfaceItemIdentifier("TootItem")
  
  private var dateTextView: RelativeDateTextView!
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
      
      dateTextView.date = model.status.createdAt
      creatorName.set(html: usernameHtml)
      tootTextView.set(html: model.status.content)
      
      actionDescription.set(html: model.action?.descriptionHtml ?? "")
    }
  }
  
  override func loadView() {
    view = FlippedView()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dateTextView = RelativeDateTextView(frame: .zero)
    dateTextView.prepareAsLabel()
    dateTextView.alphaValue = 0.7
    view.addSubview(dateTextView)
    
    tootTextView = NSTextView(frame: .zero)
    tootTextView.prepareAsLabel()
    view.addSubview(tootTextView)
    
    creatorName = NSTextView(frame: .zero)
    creatorName.prepareAsLabel()
    view.addSubview(creatorName)
    
    creatorAvatar = AvatarView(frame: .zero)
    view.addSubview(creatorAvatar)
    
    actionDescription = NSTextView(frame: .zero)
    actionDescription.prepareAsLabel()
    view.addSubview(actionDescription)
    
    actorAvatar = AvatarView(frame: .zero)
    view.addSubview(actorAvatar)
    
    let doubleClickGR = NSClickGestureRecognizer(target: self, action: #selector(didDoubleClick(_:)))
    doubleClickGR.numberOfClicksRequired = 2
    view.addGestureRecognizer(doubleClickGR)
  }
  
  @objc func didDoubleClick(_ gestureRecognizer: NSClickGestureRecognizer) {
    NSWorkspace.shared.open(model!.status.url!)
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
    
    dateTextView.shouldUpdate = true
  }
  
  func didEndDisplaying() {
    Nuke.cancelRequest(for: creatorAvatar)
    dateTextView.shouldUpdate = false
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
    let margin = CellLayout.margin
    let avatarSize = AvatarView.size(.regular)

    let textColumn = CellLayout.layoutActorRow(hasActorRow: model?.action != nil, width: width, avatar: actorAvatar, description: actionDescription)
    
    let imageFrame = CGRect(origin: CGPoint(x: margin.left, y: textColumn.minY), size: avatarSize)
    creatorAvatar.frame = imageFrame

    let dateWidth = CGFloat(40)
    let usernameFrame = CGRect(origin: textColumn.origin, size: creatorName.sizeFor(width: textColumn.width - dateWidth - CGFloat(5)))
    creatorName.frame = usernameFrame
    
    let dateFrame = CGRect(x: textColumn.maxX - dateWidth, y: textColumn.minY, width: dateWidth, height: usernameFrame.height)
    dateTextView.frame = dateFrame
    
    let tootFrame = CGRect(origin: CGPoint(x: textColumn.minX, y: usernameFrame.maxY + CellLayout.textViewYOffset), size: tootTextView.sizeFor(width: textColumn.width))
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
