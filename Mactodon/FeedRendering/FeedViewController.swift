// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

class FeedViewController: NSViewController {
  private let feedProvider: FeedProvider<Status>
  private var scrollView: NSScrollView!
  private var collectionView: NSCollectionView!
  private var pullToRefreshCell: PullToRefreshCell?
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
    
    collectionView.register(PullToRefreshCell.self, forItemWithIdentifier: PullToRefreshCell.identifier)
    collectionView.register(TootItem.self, forItemWithIdentifier: TootItem.identifier)
    
    self.collectionView = collectionView
    
    let scrollView = NSScrollView(frame: .zero)
    scrollView.documentView = collectionView
    scrollView.postsBoundsChangedNotifications = true
    NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(notification:)), name:NSView.boundsDidChangeNotification, object: scrollView.contentView)
    self.scrollView = scrollView
    self.view = scrollView
    
    // Pull to refresh cell needs to be able to draw out of bounds
    collectionView.wantsLayer = true
    collectionView.layer!.masksToBounds = false
  }
  
  init(feedProvider: FeedProvider<Status>) {
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
  
  func refresh() {
    feedProvider.reload()
  }
}

extension FeedViewController: FeedProviderDelegate {
  func didSet(itemCount: Int) {
    self.pullToRefreshCell?.refreshing = false
    collectionView.reloadData()
  }
  
  func didPrepend(itemCount: Int) {
    self.pullToRefreshCell?.refreshing = false
    collectionView.reloadData()
  }
  
  func didAppend(itemCount: Int) {
    let end = feedProvider.items.count
    let start = end - itemCount
    let indexPaths = Set((start..<end).map { (item) -> IndexPath in
      return IndexPath(item: item, section: 0)
    })
    
    self.pullToRefreshCell?.refreshing = false
    collectionView.insertItems(at: indexPaths)
  }
  
  func feedProviderReady() {
    feedProvider.reload()
  }
}

extension FeedViewController: PullToRefreshCellDelegate {
  func startRefresh() {
    feedProvider.reload()
  }
}

extension FeedViewController {
  enum CellContent {
    case pullToRefresh
    case toot(model: TootItemModel)
  }
  
  func contentFor(indexPath: IndexPath) -> CellContent {
    switch indexPath.item {
    case 0:
      return .pullToRefresh
    default:
      return .toot(model: TootItemModel(status: feedProvider.items[indexPath.item - 1]))
    }
  }
}

extension FeedViewController: NSCollectionViewDelegate {
  func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
    guard let item = item as? FeedViewCell else {
      return
    }
    
    item.willDisplay()
  }
  
  func collectionView(_ collectionView: NSCollectionView, didEndDisplaying item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
    guard let item = item as? FeedViewCell else {
      return
    }
    
    item.didEndDisplaying()
  }
}

extension FeedViewController: NSCollectionViewDataSource {
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return feedProvider.items.count
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    switch contentFor(indexPath: indexPath) {
    case .pullToRefresh:
      let view = collectionView.makeItem(withIdentifier: PullToRefreshCell.identifier, for: indexPath) as! PullToRefreshCell
      view.delegate = self
      self.pullToRefreshCell = view
      return view
    case .toot(let model):
      let view = collectionView.makeItem(withIdentifier: TootItem.identifier, for: indexPath) as! TootItem
      view.model = model
      return view
    }
  }
}

extension FeedViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
    let width = collectionView.bounds.width
    switch contentFor(indexPath: indexPath) {
    case .pullToRefresh:
      return PullToRefreshCell.size(width: width, isReloading: feedProvider.isLoading)
    case .toot(let model):
      return TootItem.size(width: width, toot: model)
    }
  }
}
