// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class FeedViewNotificationCellProvider: FeedViewCellProvider {
  typealias Notification = MastodonKit.Notification
  private let notificationFeedProvider: FeedProvider<Notification>
  var feedProvider: TypelessFeedProvider {
    get {
      return notificationFeedProvider
    }
  }
  
  init(feedProvider: FeedProvider<Notification>) {
    self.notificationFeedProvider = feedProvider
  }
  
  func prepare(collectionView: NSCollectionView) {
    collectionView.register(TootItem.self, forItemWithIdentifier: TootItem.identifier)
    collectionView.register(FollowingItem.self, forItemWithIdentifier: FollowingItem.identifier)
  }
  
  var itemCount: Int {
    get {
      return notificationFeedProvider.items.count
    }
  }
  
  func item(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> NSCollectionViewItem {
    let notification = notificationFeedProvider.items[index]
    if let model = TootItemModel(notification: notification) {
      let view = collectionView.makeItem(withIdentifier: TootItem.identifier, for: indexPath) as! TootItem
      view.model = model
      return view
    } else {
      let view = collectionView.makeItem(withIdentifier: FollowingItem.identifier, for: indexPath) as! FollowingItem
      view.account = notification.account
      return view
    }
  }
  
  func itemSize(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> CGSize {
    let notification = notificationFeedProvider.items[index]
    if let model = TootItemModel(notification: notification) {
      return TootItem.size(width: collectionView.bounds.width, toot: model)
    } else {
      return FollowingItem.size(width: collectionView.bounds.width)
    }
  }
}
