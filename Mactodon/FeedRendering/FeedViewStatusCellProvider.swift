// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

class FeedViewStatusCellProvider: FeedViewCellProvider {
  weak var delegate: FeedViewCellProviderDelegate?
  
  var feedProvider: TypelessFeedProvider {
    get {
      return statusFeedProvider
    }
  }
  
  private let statusFeedProvider: FeedProvider<Status>
  
  init(feedProvider: FeedProvider<Status>) {
    self.statusFeedProvider = feedProvider
  }
  
  func prepare(collectionView: NSCollectionView) {
    collectionView.register(TootItem.self, forItemWithIdentifier: TootItem.identifier)
  }
  
  var itemCount: Int {
    get {
      return statusFeedProvider.items.count
    }
  }
  
  func item(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> NSCollectionViewItem {
    let view = collectionView.makeItem(withIdentifier: TootItem.identifier, for: indexPath) as! TootItem
    view.model = TootItemModel(status: statusFeedProvider.items[index])
    return view
  }
  
  func itemSize(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> CGSize {
    return TootItem.size(width: collectionView.bounds.width, toot: TootItemModel(status: statusFeedProvider.items[index]))
  }
}
