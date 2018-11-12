// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

protocol FeedProviderDelegate: AnyObject {
  func feedProviderReady()
  func didSet(itemCount: Int)
  func didPrepend(itemCount: Int)
  func didAppend(itemCount: Int)
}

protocol TypelessFeedProvider: AnyObject {
  var delegate: FeedProviderDelegate? { get set }
  var isLoading: Bool { get }
  var ready: Bool { get }
  func reload()
  func loadMore()
}

class FeedProvider<T: Codable>: TypelessFeedProvider {
  typealias TimelineRequest = (_ range: RequestRange) -> Request<[T]>
  
  var items: [T] = []
  
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
  private let streamingClient: ValuePromise<StreamingClient?> = ValuePromise(initialValue: nil)
  private let request: TimelineRequest
  private var _isLoading = false
  private var nextPage: RequestRange?
  private var previousPage: RequestRange?
  var sc: StreamingClient?

  public init(client: ValuePromise<Client?>, request: @escaping TimelineRequest, streamingEndpoint: String? = nil) {
    self.client = client
    self.request = request
    self.client.didSet.then {
      self.delegate?.feedProviderReady()
    }
    
    if let streamingEndpoint = streamingEndpoint {
      self.client.didSet.then { [weak self] (client) in
        guard let client = client else {
          return
        }
        
        let url = URL(string: "https://chaos.social/" + streamingEndpoint)!
        let streamingClient = StreamingClient(url: url, accessToken: client.accessToken)
        streamingClient.connect()
        self?.streamingClient.value = streamingClient
        self?.sc = streamingClient
      }
    }
  }
  
  static func user(client: ValuePromise<Client?>) -> FeedProvider<Status> {
    return FeedProvider<Status>(client: client, request: { (range) -> Request<[Status]> in
      return Timelines.home(range: range)
    }, streamingEndpoint: "api/v1/streaming/?stream=user")
  }
  
  static func local(client: ValuePromise<Client?>) -> FeedProvider<Status> {
    return FeedProvider<Status>(client: client, request: { (range) -> Request<[Status]> in
      return Timelines.public(local: true, range: range)
    }, streamingEndpoint: "api/v1/streaming/public/local")
  }
  
  static func federated(client: ValuePromise<Client?>) -> FeedProvider<Status> {
    return FeedProvider<Status>(client: client, request: { (range) -> Request<[Status]> in
      return Timelines.public(local: false, range: range)
    }, streamingEndpoint: "api/v1/streaming/public")
  }
  
  static func notifications(client: ValuePromise<Client?>) -> FeedProvider<MastodonKit.Notification> {
    return FeedProvider<MastodonKit.Notification>(client: client, request: { (range) -> Request<[MastodonKit.Notification]> in
      return Notifications.all(range: range)
    }, streamingEndpoint: "api/v1/streaming/user")
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
      self.items = result.value
      self.delegate?.didSet(itemCount: result.value.count)
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
      self.items += result.value
      self.delegate?.didSet(itemCount: result.value.count)
      self.nextPage = result.pagination?.next
    }.fail({ [weak self] (_) in
      self?._isLoading = false
    })
  }
}
