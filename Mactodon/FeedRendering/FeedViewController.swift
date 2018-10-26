// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

class FeedViewController: NSViewController {
  private let feedProvider: FeedProvider
  private var timeline: [Status] = []
  private var scrollView: NSScrollView!
  private var collectionView: NSCollectionView!
  private lazy var preheater = ImagePreheater()
  
  class Layout: NSCollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
      if (newBounds.width == collectionViewContentSize.width) {
        return false
      }
      
      invalidateLayout()
      return true
    }
  }
  
  override func loadView() {
    let collectionView = NSCollectionView(frame: .zero)
    collectionView.delegate = self
    collectionView.autoresizingMask = [.width, .height]
    let layout = Layout()
    layout.minimumLineSpacing = 1
    layout.minimumInteritemSpacing = 0
    collectionView.collectionViewLayout = layout
    collectionView.dataSource = self
    
    collectionView.register(TootItem.self, forItemWithIdentifier: TootItem.identifier)
    
    self.collectionView = collectionView
    
    let scrollView = NSScrollView(frame: .zero)
    scrollView.documentView = collectionView
    scrollView.postsBoundsChangedNotifications = true
    NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(notification:)), name:NSView.boundsDidChangeNotification, object: scrollView.contentView)
    self.scrollView = scrollView
    self.view = scrollView
  }
  
  init(feedProvider: FeedProvider) {
    self.feedProvider = feedProvider
    super.init(nibName: nil, bundle: nil)
    self.feedProvider.delegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func boundsDidChange(notification: Foundation.Notification) {
    if !feedProvider.ready || feedProvider.isLoading {
      return
    }
    
    guard let documentView = scrollView.documentView else {
      return
    }
    
    let remainingPages = (documentView.frame.height - scrollView.documentVisibleRect.maxY) / scrollView.bounds.height
    if remainingPages < 2.5 {
      feedProvider.loadMore()
    }
  }
  
  func prefetch(statuses: [Status]) {
    let imageURLs = statuses.map { (status) in
      return URL(string: status.account.avatar)!
    }
    preheater.startPreheating(with: imageURLs)
  }
}

extension FeedViewController: FeedProviderDelegate {
  func set(feedItems: [Status]) {
    timeline = feedItems
    collectionView.reloadData()
  }
  
  func prepend(feedItems items: [Status]) {
    timeline = items + timeline
    collectionView.reloadData()
  }
  
  func append(feedItems items: [Status]) {
    let indexPaths = Set((timeline.count...(timeline.count + items.count)).map { (item) -> IndexPath in
      return IndexPath(item: item, section: 0)
    })
    
    timeline += items
    
    collectionView.insertItems(at: indexPaths)
  }
  
  func feedProviderReady() {
    feedProvider.reload()
  }
}

extension FeedViewController: NSCollectionViewDelegate {
  func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
    guard let item = item as? TootItem else {
      return
    }
    
    item.willDisplay()
  }
  
  func collectionView(_ collectionView: NSCollectionView, didEndDisplaying item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
    guard let item = item as? TootItem else {
      return
    }
    
    item.didEndDisplaying()
  }
}

extension FeedViewController: NSCollectionViewDataSource {
  static var sizingTootView: TootItem = {
    let item = TootItem(nibName: nil, bundle: nil)
    let _ = item.view
    return item
  }()
  
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return timeline.count
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: TootItem.identifier, for: indexPath) as! TootItem
    item.status = timeline[indexPath.item]
    return item
  }
}

extension FeedViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
    let item = FeedViewController.sizingTootView
    item.status = timeline[indexPath.item]
    return item.layout(width: collectionView.bounds.width)
  }
}
