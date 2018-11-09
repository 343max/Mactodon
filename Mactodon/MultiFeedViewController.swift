// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class MultiFeedViewController: NSViewController {
  enum Feed: Int {
    case UserTimeline
    case LocalTimeline
    case FederatedTimeline
    case Notifications
  }
  
  let client: ValuePromise<Client?>
  
  var feedViewControllers: [Feed: FeedViewController] = [:]
  var selectedFeed = Feed.UserTimeline {
    didSet {
      updateSelectedFeedViewController()
    }
  }
  
  init(client: ValuePromise<Client?>) {
    self.client = client
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    view = NSView()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    updateSelectedFeedViewController()
  }
  
  func updateSelectedFeedViewController() {
    children.forEach { (vc) in
      vc.removeFromParent()
      vc.view.removeFromSuperview()
    }
    
    let selectedVC = selectedFeedViewController
    selectedVC.view.autoresizingMask = [.width, .height]
    selectedVC.view.frame = view.bounds
    addChild(selectedVC)
    view.addSubview(selectedVC.view)
  }
  
  func createViewController(feed: Feed) -> FeedViewController {
    switch feed {
    case .UserTimeline:
      return FeedViewController(feedProvider: FeedProvider<Status>.user(client: client))
    case .LocalTimeline:
      return FeedViewController(feedProvider: FeedProvider<Status>.local(client: client))
    case .FederatedTimeline:
      return FeedViewController(feedProvider: FeedProvider<Status>.federated(client: client))
    case .Notifications:
      let cellProvider = FeedViewNotificationCellProvider(feedProvider: FeedProvider<MastodonKit.Notification>.notifications(client: client))
      return FeedViewController(cellProvider: cellProvider)
    }
  }
  
  func cachedViewController(feed: Feed) -> FeedViewController {
    if let viewController = feedViewControllers[selectedFeed] {
      return viewController
    } else {
      let viewController = self.createViewController(feed: selectedFeed)
      feedViewControllers[selectedFeed] = viewController
      return viewController
    }
  }
  
  var selectedFeedViewController: FeedViewController {
    get {
      return cachedViewController(feed: selectedFeed)
    }
  }
  
  func refresh() {
    selectedFeedViewController.refresh()
  }
}