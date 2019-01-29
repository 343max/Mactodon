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
    
    feedProvider.prepare = { [weak self] (items) in
      guard let self = self else {
        return
      }
      
      let ids = items.filter({ $0.type == .follow }).map({ $0.account.id })
      self.client.value!.run(Accounts.relationships(ids: ids)).mainQueue.then { relationships in
        relationships.forEach({ (relationship) in
          self.update(following: relationship.following ? .Following : .NotFollowing, accountId: relationship.id)
        })
      }
    }
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
  
  func update(following: FollowingItem.FollowingState, accountId: String) {
    followings[accountId] = following
    reloadFollowNotificationCell(accountId: accountId)
  }
  
  private func indexForFollowNotification(followerId: String) -> Int? {
    return notificationFeedProvider.items.firstIndex(where: { (notification) -> Bool in
      return (notification.type == .follow) && (notification.account.id == followerId)
    })
  }
  
  func reloadFollowNotificationCell(accountId: String) {
    guard let index = indexForFollowNotification(followerId: accountId) else {
      return
    }
    
    delegate?.updateCell(index: index)
  }
  
  func followingModel(account: Account) -> FollowingItem.Model {
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
      view.model = followingModel(account: notification.account)
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
    self.update(following: .FollowRequested, accountId: account.id)
    
    client.value!.run(Accounts.follow(id: account.id)).mainQueue.then { [weak self] in
      self?.update(following: .Following, accountId: account.id)
    }.fail { [weak self] (_) in
      self?.update(following: .NotFollowing, accountId: account.id)
    }
  }
  
  func unfollow(account: Account) {
    self.update(following: .UnfollowRequested, accountId: account.id)
    
    client.value!.run(Accounts.follow(id: account.id)).mainQueue.then { [weak self] in
      self?.update(following: .NotFollowing, accountId: account.id)
    }.fail { [weak self] (_) in
      self?.update(following: .Following, accountId: account.id)
    }
  }
}
