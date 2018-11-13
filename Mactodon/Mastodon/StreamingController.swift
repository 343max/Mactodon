// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

private class InstanceUrls: Codable {
  public let urls: [String: String]
}

class StreamingController {
  let client: Client
  let instanceDomain: String
  
  lazy var userStream: StreamingClient = {
    return streamingClient(timeline: .User)
  }()
  
  lazy var localStream: StreamingClient = {
    return streamingClient(timeline: .Local)
  }()
  
  lazy var federatedStream: StreamingClient = {
    return streamingClient(timeline: .Federated)
  }()

  init(client: Client, instanceDomain: String) {
    assert(client.accessToken != nil)
    self.client = client
    self.instanceDomain = instanceDomain
  }
  
  static func controller(client: Client) -> Promise<StreamingController> {
    return client.run(Instances.current()).map { return StreamingController(client: client, instanceDomain: $0.uri) }
  }
  
  func streamingClient(timeline: StreamingClient.Timeline) -> StreamingClient {
    let client = StreamingClient(instance: instanceDomain, timeline: timeline, accessToken: self.client.accessToken!)
    client.connect()
    return client
  }
}
