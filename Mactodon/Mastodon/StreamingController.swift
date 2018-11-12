// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

private class InstanceUrls: Codable {
  public let urls: [String: String]
}

class StreamingController {
  let client: Client
  let instanceDomain = Promise<String>()
  
  lazy var userStream: Promise<StreamingClient> = {
    return streamingClient(timeline: .User)
  }()
  
  lazy var localStream: Promise<StreamingClient> = {
    return streamingClient(timeline: .Local)
  }()
  
  lazy var federatedStream: Promise<StreamingClient> = {
    return streamingClient(timeline: .Federated)
  }()

  init(client: Client) {
    assert(client.accessToken != nil)
    self.client = client
    
    client.run(Instances.current()).then { [weak self] (instance) in
      self?.instanceDomain.fulfill(instance.uri)
    }
  }
  
  func streamingClient(timeline: StreamingClient.Timeline) -> Promise<StreamingClient> {
    let promise = Promise<StreamingClient>()
    instanceDomain.then { [weak self] (instance) in
      guard let self = self else { return }
      let client = StreamingClient(instance: instance, timeline: timeline, accessToken: self.client.accessToken!)
      client.connect()
      promise.fulfill(client)
    }
    return promise
  }
}
