// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit
import Starscream

protocol StreamingClientDelegate: AnyObject {
  func connected(streamingClient: StreamingClient)
  func disconnected(streamingClient: StreamingClient, error: Error?)
  func received(status: Status, streamingClient: StreamingClient)
  func received(notification: MastodonKit.Notification, streamingClient: StreamingClient)
  func deleted(statusID: String, streamingClient: StreamingClient)
  func filtersChanged(streamingClient: StreamingClient)
}

class StreamingClient {
  let socket: WebSocket
  weak var delegate: StreamingClientDelegate?
  
  init(url: URL, accessToken: String?) {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    if let accessToken = accessToken {
      request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
    }
    self.socket = WebSocket(request: request)
    self.socket.delegate = self
  }
  
  func connect() {
    socket.connect()
  }
  
  func disconnect() {
    socket.disconnect()
  }
}

extension StreamingClient: WebSocketDelegate {
  func websocketDidConnect(socket: WebSocketClient) {
    delegate?.connected(streamingClient: self)
  }
  
  func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    delegate?.disconnected(streamingClient: self, error: error)
  }
  
  func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    handleResponse(data: text.data(using: .utf8)!)
  }
  
  func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    assert(false)
  }
  
  private func handleResponse(data: Data) {
    let event = try! JSONDecoder().decode(Event.self, from: data)
    switch event {
    case .Update(let status):
      delegate?.received(status: status, streamingClient: self)
    case .Notification(let notification):
      delegate?.received(notification: notification, streamingClient: self)
    case .Delete(let statusID):
      delegate?.deleted(statusID: statusID, streamingClient: self)
    case .FiltersChanged:
      delegate?.filtersChanged(streamingClient: self)
    }
  }
}


// protected helper, copied from MastodonKit
private extension DateFormatter {
  static let mastodonFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    
    return dateFormatter
  }()
}

// protected helper, copied from MastodonKit
private extension Decodable {
  static func decode(data: Data) throws -> Self {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(.mastodonFormatter)
    return try decoder.decode(Self.self, from: data)
  }
}

extension StreamingClient {
  fileprivate enum Event: Decodable {
    case Update(status: Status)
    case Notification(notification: MastodonKit.Notification)
    case Delete(id: String)
    case FiltersChanged
    
    struct RawEvent: Decodable {
      enum Kind: String, Decodable {
        case Update = "update"
        case Notification = "notification"
        case Delete = "delete"
        case FiltersChanged = "filters_changed"
      }
      
      let event: Kind
      let payload: String?
      
      var payloadData: Data? {
        get {
          return payload?.data(using: .utf8)
        }
      }
    }
    
    init(from decoder: Decoder) throws {
      let rawEvent = try RawEvent(from: decoder)
      switch rawEvent.event {
      case .Update:
        print("\(rawEvent.payload!)")
        let status = try Status.decode(data: rawEvent.payloadData!)
        self = .Update(status: status)
      case .Notification:
        print("\(rawEvent.payload!)")
        let notification = try MastodonKit.Notification.decode(data: rawEvent.payloadData!)
        self = .Notification(notification: notification)
      case .Delete:
        let id = rawEvent.payload!
        self = .Delete(id: id)
      case .FiltersChanged:
        self = .FiltersChanged
      }
    }
  }
}
