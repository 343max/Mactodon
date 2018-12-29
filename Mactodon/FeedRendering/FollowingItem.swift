// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

class FollowingItem: NSCollectionViewItem, FeedViewCell {
  enum FollowingState {
    case NotFollowing
    case FollowRequested
    case Following
    case UnfollowRequested
  }
  
  struct Model {
    let account: Account
    let followingState: FollowingState
    let follow: (_ account: Account) -> ()
    let unfollow: (_ account: Account) -> ()
  }
  
  static let identifier = NSUserInterfaceItemIdentifier("FollowingItem")
  var model: Model?
  
  private var actorAvatar: AvatarView!
  private var descriptionView: NSTextView!
  private var actionButton: NSButton!
  
  func willDisplay() {
    guard let model = model else {
      return
    }
    
    Nuke.loadImage(with: URL(string: model.account.avatar)!, into: actorAvatar)
    actorAvatar.clickURL = URL(string: model.account.url)
    
    descriptionView.set(html: "\(model.account.someDisplayName) followed you")
    
    switch model.followingState {
    case .NotFollowing:
      actionButton.title = "Follow"
      actionButton.isEnabled = true
    case .FollowRequested:
      actionButton.title = "Follow"
      actionButton.isEnabled = false
    case .Following:
      actionButton.title = "Unfollow"
      actionButton.isEnabled = true
    case .UnfollowRequested:
      actionButton.title = "Unfollow"
      actionButton.isEnabled = false
    }
  }
  
  func didEndDisplaying() {
    Nuke.cancelRequest(for: actorAvatar)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    model = nil
  }
  
  override func loadView() {
    view = FlippedView()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    actorAvatar = AvatarView(frame: .zero)
    view.addSubview(actorAvatar)
    
    descriptionView = NSTextView(frame: .zero)
    descriptionView.prepareAsLabel()
    view.addSubview(descriptionView)
    
    actionButton = NSButton(title: "Follow", target: self, action: #selector(clickedFollowButton(_:)))
    actionButton.bezelStyle = .roundRect
    actionButton.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
    view.addSubview(actionButton)
  }
  
  @IBAction func clickedFollowButton(_ sender: NSButton) {
    guard let model = model else {
      assert(false)
      return
    }
    switch model.followingState {
    case .Following:
      model.unfollow(model.account)
    case .NotFollowing:
      model.follow(model.account)
    default:
      assert(false)
    }
  }
  
  func layout(width: CGFloat) {
    CellLayout.layoutActorRow(hasActorRow: true, width: width, avatar: actorAvatar, description: descriptionView)
    
    actionButton.sizeToFit()
    var buttonFrame = view.frame.alignedRect(size: actionButton.frame.size, horizontalOffset: 1.0, verticalOffset: 0.5)
    buttonFrame.origin.x -= CellLayout.margin.right
    actionButton.frame = buttonFrame
  }
  
  override func viewDidLayout() {
    super.viewDidLayout()
    layout(width: view.bounds.width)
  }
  
  static func size(width: CGFloat) -> CGSize {
    return CGSize(width: width,
                  height: CellLayout.margin.top + AvatarView.size(.small).height + CellLayout.margin.bottom)
  }
}
