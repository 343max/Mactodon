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
  let streamingController: ValuePromise<StreamingController?>
  
  var feedViewControllers: [Feed: FeedViewController] = [:]
  var selectedFeed = Feed.UserTimeline {
    didSet {
      updateSelectedFeedViewController()
    }
  }
  
  init(client: ValuePromise<Client?>, streamingController: ValuePromise<StreamingController?>) {
    self.client = client
    self.streamingController = streamingController
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
  
  func createSignal<T: Codable>(_ callback: @escaping (_ streamingController: StreamingController) -> (Promise<T>)) -> Promise<T> {
    return Promise<T>({ [weak self] (completion) in
      self?.streamingController.didChange.then { (streamingController) in
        if let streamingController = streamingController {
          callback(streamingController).then {
            completion($0)
          }
        }
      }
    }, multiCall: true)
  }
  
  func createViewController(feed: Feed) -> FeedViewController {
    switch feed {
    case .UserTimeline:
      let signal = createSignal { $0.userStream.statusSignal }
      let deleteSignal = createSignal { $0.userStream.deletedSignal }
      return FeedViewController(feedProvider: FeedProvider<Status>.user(client: client, newStatusSignal: signal, deleteStatusSignal: deleteSignal))
    case .LocalTimeline:
      let signal = createSignal { $0.localStream.statusSignal }
      let deleteSignal = createSignal { $0.localStream.deletedSignal }
      return FeedViewController(feedProvider: FeedProvider<Status>.local(client: client, newStatusSignal: signal, deleteStatusSignal: deleteSignal))
    case .FederatedTimeline:
      let signal = createSignal { $0.federatedStream.statusSignal }
      let deleteSignal = createSignal { $0.federatedStream.deletedSignal }
      return FeedViewController(feedProvider: FeedProvider<Status>.federated(client: client, newStatusSignal: signal, deleteStatusSignal: deleteSignal))
    case .Notifications:
      let signal = Promise({ [weak self] (completion, _) in
        self?.streamingController.didChange.then { (streamingController) in
          streamingController?.userStream.notificationSignal.then { notification in
            completion(notification)
          }
        }
      }, multiCall: true)
      let feedProvider = FeedProvider<MastodonKit.Notification>.notifications(client: client, newNotificationSignal: signal)
      let cellProvider = FeedViewNotificationCellProvider(feedProvider: feedProvider, client: client)
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
