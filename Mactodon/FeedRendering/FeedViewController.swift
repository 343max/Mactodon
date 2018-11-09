// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke

protocol FeedViewCellProvider {
  var feedProvider: TypelessFeedProvider { get }
  func prepare(collectionView: NSCollectionView)
  var itemCount: Int { get }
  func item(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> NSCollectionViewItem
  func itemSize(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> CGSize
}

class FeedViewStatusCellProvider: FeedViewCellProvider {
  var feedProvider: TypelessFeedProvider {
    get {
      return _feedProvider
    }
  }
  
  private let _feedProvider: FeedProvider<Status>
  weak var delegate: FeedProviderDelegate? {
    get {
      return _feedProvider.delegate
    }
    set {
      _feedProvider.delegate = delegate
    }
  }
  
  init(feedProvider: FeedProvider<Status>) {
    self._feedProvider = feedProvider
  }

  func prepare(collectionView: NSCollectionView) {
    collectionView.register(TootItem.self, forItemWithIdentifier: TootItem.identifier)
  }
  
  var itemCount: Int {
    get {
      return _feedProvider.items.count
    }
  }
  
  func item(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> NSCollectionViewItem {
    let view = collectionView.makeItem(withIdentifier: TootItem.identifier, for: indexPath) as! TootItem
    view.model = TootItemModel(status: _feedProvider.items[index])
    return view
  }
  
  func itemSize(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> CGSize {
    return TootItem.size(width: collectionView.bounds.width, toot: TootItemModel(status: _feedProvider.items[index]))
  }
}

class FeedViewController: NSViewController {
  typealias T = Status
  private let cellProvider: FeedViewCellProvider
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
    cellProvider.prepare(collectionView: collectionView)
    
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
  
  init(cellProvider: FeedViewCellProvider) {
    self.cellProvider = cellProvider
    super.init(nibName: nil, bundle: nil)
    self.cellProvider.feedProvider.delegate = self
  }
  
  convenience init(feedProvider: FeedProvider<Status>) {
    let cellProvider = FeedViewStatusCellProvider(feedProvider: feedProvider)
    self.init(cellProvider: cellProvider)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func boundsDidChange(notification: Foundation.Notification) {
    if !cellProvider.feedProvider.ready || cellProvider.feedProvider.isLoading {
      return
    }
    
    guard let documentView = scrollView.documentView else {
      return
    }
    
    let remainingPages = (documentView.frame.height - scrollView.documentVisibleRect.maxY) / scrollView.bounds.height
    if remainingPages < 2.5 {
      cellProvider.feedProvider.loadMore()
    }
  }
  
  func prefetch(statuses: [Status]) {
    let imageURLs = statuses.map { (status) in
      return URL(string: status.account.avatar)!
    }
    preheater.startPreheating(with: imageURLs)
  }
  
  func refresh() {
    cellProvider.feedProvider.reload()
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
    let end = cellProvider.itemCount
    let start = end - itemCount
    let indexPaths = Set((start..<end).map { (item) -> IndexPath in
      return IndexPath(item: item, section: 0)
    })
    
    self.pullToRefreshCell?.refreshing = false
    collectionView.insertItems(at: indexPaths)
  }
  
  func feedProviderReady() {
    cellProvider.feedProvider.reload()
  }
}

extension FeedViewController: PullToRefreshCellDelegate {
  func startRefresh() {
    cellProvider.feedProvider.reload()
  }
}

extension FeedViewController {
  enum CellContent {
    case pullToRefresh
    case feedItem(index: Int)
  }
  
  func contentFor(indexPath: IndexPath) -> CellContent {
    switch indexPath.item {
    case 0:
      return .pullToRefresh
    default:
      return .feedItem(index: indexPath.item - 1)
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
    return cellProvider.itemCount
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    switch contentFor(indexPath: indexPath) {
    case .pullToRefresh:
      let view = collectionView.makeItem(withIdentifier: PullToRefreshCell.identifier, for: indexPath) as! PullToRefreshCell
      view.delegate = self
      self.pullToRefreshCell = view
      return view
    case .feedItem(let index):
      return cellProvider.item(collectionView: collectionView, indexPath: indexPath, index: index)
    }
  }
}

extension FeedViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.width
    switch contentFor(indexPath: indexPath) {
    case .pullToRefresh:
      return PullToRefreshCell.size(width: width, isReloading: cellProvider.feedProvider.isLoading)
    case .feedItem(let index):
      return cellProvider.itemSize(collectionView: collectionView, indexPath: indexPath, index: index)
    }
  }
}
