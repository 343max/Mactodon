// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class FeedViewController: NSViewController {
  private let feedProvider: FeedProvider
  private var timeline: [Status] = []
  private var scrollView: NSScrollView!
  private var collectionView: NSCollectionView!
  
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
    
    collectionView.register(TootCollectionViewItem.self, forItemWithIdentifier: TootCollectionViewItem.identifier)
    
    self.collectionView = collectionView
    
    let scrollView = NSScrollView(frame: .zero)
    scrollView.documentView = collectionView
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
    timeline += items
    collectionView.reloadData()
  }
  
  func feedProviderReady() {
    feedProvider.reload()
  }
}

extension FeedViewController: NSCollectionViewDelegate {
  
}

extension FeedViewController: NSCollectionViewDataSource {
  static var sizingTootView: TootCollectionViewItem = {
    let item = TootCollectionViewItem(nibName: nil, bundle: nil)
    let _ = item.view
    return item
  }()
  
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return timeline.count
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: TootCollectionViewItem.identifier, for: indexPath) as! TootCollectionViewItem
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
