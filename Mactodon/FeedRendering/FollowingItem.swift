// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

class FollowingItem: NSCollectionViewItem, FeedViewCell {
  static let identifier = NSUserInterfaceItemIdentifier("FollowingItem")
  var account: Account?
  
  private var actorAvatar: AvatarView!
  private var descriptionView: NSTextView!
  private var actionButton: NSButton!
  
  func willDisplay() {
    guard let account = account else {
      return
    }
    
    Nuke.loadImage(with: URL(string: account.avatar)!, into: actorAvatar)
    actorAvatar.clickURL = URL(string: account.url)
    
    descriptionView.set(html: "\(account.someDisplayName) followed you")
  }
  
  func didEndDisplaying() {
    Nuke.cancelRequest(for: actorAvatar)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    account = nil
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
    print("follow!")
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
