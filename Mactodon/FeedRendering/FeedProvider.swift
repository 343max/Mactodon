// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

protocol FeedProviderDelegate: AnyObject {
  func feedProviderReady()
  func set(feedItems: [Status])
  func prepend(feedItems: [Status])
  func append(feedItems: [Status])
}

protocol FeedProvider: AnyObject {
  var delegate: FeedProviderDelegate? { get set }
  func reload()
  func loadMore()
}

class TimelineFeedProvider: FeedProvider {
  weak var delegate: FeedProviderDelegate? {
    didSet {
      if client.value != nil {
        delegate?.feedProviderReady()
      }
    }
  }
  let client: ValuePromise<Client?>
  
  init(client: ValuePromise<Client?>) {
    self.client = client
    self.client.didSet.then {
      self.delegate?.feedProviderReady()
    }
  }
  
  func reload() {
    client.value?.runPaginated(Timelines.home()).then { [weak self] (result) in
      self?.delegate?.set(feedItems: result.value)
    }
  }
  
  func loadMore() {
    //
  }
}
