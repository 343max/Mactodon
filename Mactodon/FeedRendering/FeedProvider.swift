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
  var isLoading: Bool { get }
  var ready: Bool { get }
  func reload()
  func loadMore()
}

class TimelineFeedProvider: FeedProvider {
  typealias TimelineRequest = (_ range: RequestRange) -> Request<[Status]>
  weak var delegate: FeedProviderDelegate? {
    didSet {
      if client.value != nil {
        delegate?.feedProviderReady()
      }
    }
  }

  var isLoading: Bool {
    get {
      return _isLoading
    }
  }
  
  var ready: Bool {
    get {
      return client.value != nil
    }
  }

  private let client: ValuePromise<Client?>
  private let request: TimelineRequest
  private var _isLoading = false
  private var nextPage: RequestRange?
  private var previousPage: RequestRange?

  public init(client: ValuePromise<Client?>, request: @escaping TimelineRequest) {
    self.client = client
    self.request = request
    self.client.didSet.then {
      self.delegate?.feedProviderReady()
    }
  }
  
  
  
  static func user(client: ValuePromise<Client?>) -> TimelineFeedProvider {
    return TimelineFeedProvider(client: client, request: { (range) -> Request<[Status]> in
      return Timelines.home(range: range)
    })
  }
  
  static func local(client: ValuePromise<Client?>) -> TimelineFeedProvider {
    return TimelineFeedProvider(client: client, request: { (range) -> Request<[Status]> in
      return Timelines.public(local: true, range: range)
    })
  }
  
  static func federated(client: ValuePromise<Client?>) -> TimelineFeedProvider {
    return TimelineFeedProvider(client: client, request: { (range) -> Request<[Status]> in
      return Timelines.public(local: false, range: range)
    })
  }
  
  func reload() {
    if (isLoading) {
      return
    }
    
    _isLoading = true
    client.value?.runPaginated(request(.default)).mainQueue.then { [weak self] (result) in
      guard let self = self else {
        return
      }
      
      self._isLoading = false
      self.delegate?.set(feedItems: result.value)
      self.previousPage = result.pagination?.previous
      self.nextPage = result.pagination?.next
      
    }.fail { [weak self] (_) in
        self?._isLoading = false
    }
  }
  
  func loadMore() {
    guard let nextPage = nextPage else {
      return
    }
    _isLoading = true
    client.value?.runPaginated(request(nextPage)).mainQueue.then { [weak self] (result) in
      guard let self = self else {
        return
      }

      self._isLoading = false
      self.delegate?.append(feedItems: result.value)
      self.nextPage = result.pagination?.next
    }.fail({ [weak self] (_) in
      self?._isLoading = false
    })
  }
}
