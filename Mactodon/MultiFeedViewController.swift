// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class MultiFeedViewController: NSViewController {
  let client: ValuePromise<Client?>
  var feedViewController: FeedViewController!
  
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
    
    let feedViewController = FeedViewController(feedProvider: TimelineFeedProvider(client: client))
    feedViewController.view.autoresizingMask = [.width, .height]
    feedViewController.view.frame = view.bounds
    addChild(feedViewController)
    view.addSubview(feedViewController.view)
    self.feedViewController = feedViewController
  }
  
  func refresh() {
    feedViewController.refresh()
  }
}
