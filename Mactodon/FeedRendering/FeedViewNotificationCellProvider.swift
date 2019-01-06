// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class FeedViewNotificationCellProvider: FeedViewCellProvider {
  weak var delegate: FeedViewCellProviderDelegate?
  
  typealias Notification = MastodonKit.Notification
  private let notificationFeedProvider: FeedProvider<Notification>
  private let client: ValuePromise<Client?>
  var feedProvider: TypelessFeedProvider {
    get {
      return notificationFeedProvider
    }
  }
  
  init(feedProvider: FeedProvider<Notification>, client: ValuePromise<Client?>) {
    self.notificationFeedProvider = feedProvider
    self.client = client
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
  
  private var followings: [String: FollowingItem.FollowingState] = [:]
  func following(account: Account) -> FollowingItem.FollowingState {
    return followings[account.id] ?? .Unknown
  }
  
  func update(following: FollowingItem.FollowingState, account: Account) {
    followings[account.id] = following
    reloadFollowNotificationCell(account: account)
  }
  
  func reloadFollowNotificationCell(account: Account) {
    guard let index = notificationFeedProvider.items.firstIndex(where: { (notification) -> Bool in
      return (notification.type == .follow) && (notification.account.id == account.id)
    }) else {
      return
    }
    
    delegate?.updateCell(index: index)
  }
  
  func model(account: Account) -> FollowingItem.Model {
    let following = self.following(account: account)
    return FollowingItem.Model(account: account, followingState: following, follow: { [weak self] (account: Account) -> () in
      self?.follow(account: account)
      }, unfollow: { [weak self] (account: Account) -> () in
      self?.unfollow(account: account)
      })
  }
  
  func item(collectionView: NSCollectionView, indexPath: IndexPath, index: Int) -> NSCollectionViewItem {
    let notification = notificationFeedProvider.items[index]
    if let model = TootItemModel(notification: notification) {
      let view = collectionView.makeItem(withIdentifier: TootItem.identifier, for: indexPath) as! TootItem
      view.model = model
      return view
    } else {
      let view = collectionView.makeItem(withIdentifier: FollowingItem.identifier, for: indexPath) as! FollowingItem
      view.model = model(account: notification.account)
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

extension FeedViewNotificationCellProvider {
  func follow(account: Account) {
    self.update(following: .FollowRequested, account: account)
    
    client.value!.run(Accounts.follow(id: account.id)).mainQueue.then { [weak self] in
      self?.update(following: .Following, account: account)
    }.fail { [weak self] (_) in
      self?.update(following: .NotFollowing, account: account)
    }
  }
  
  func unfollow(account: Account) {
    self.update(following: .UnfollowRequested, account: account)
    
    client.value!.run(Accounts.follow(id: account.id)).mainQueue.then { [weak self] in
      self?.update(following: .NotFollowing, account: account)
    }.fail { [weak self] (_) in
      self?.update(following: .Following, account: account)
    }
  }
}
