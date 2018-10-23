// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

protocol TokenControllerDelegate: AnyObject {
  func loadClientApplication(instance: String) -> ClientApplication?
  func loadLoginSettings(username: String) -> LoginSettings?
  func store(clientApplication: ClientApplication, forInstance: String)
  func store(loginSettings: LoginSettings, forUsername: String, instance: String)
  func authenticatedClient(client: Client)
  func clientName() -> String
  func open(url: URL)
}

class TokenController {
  let scopes: [AccessScope]
  let instance: String
  let uuid = UUID().uuidString
  var username: String?
  let redirectUri: String
  let baseUrl: String
  lazy var anonymousClient: Client = {
    return Client(baseURL: baseUrl)
  }()
  var authenticatedClient: Client?
  
  fileprivate static var controllers: Set<TokenController> = []
  
  weak var delegate: TokenControllerDelegate?

  var clientApplication: ClientApplication?
  var loginSettings: LoginSettings?
  
  convenience init(delegate: TokenControllerDelegate, scopes: [AccessScope], username: String, instance: String, protocolHandler: String) {
    self.init(delegate: delegate, scopes: scopes, instance: instance, protocolHandler: protocolHandler)
    self.username = username
  }
  
  init(delegate: TokenControllerDelegate, scopes: [AccessScope], instance: String, protocolHandler: String) {
    self.delegate = delegate
    self.scopes = scopes
    self.instance = instance
    self.redirectUri = "\(protocolHandler)://authenticated/?uuid=\(self.uuid)"
    self.baseUrl = "https://\(instance)/"
  }
  
  func loadStoredItems() {
    guard let delegate = delegate else {
      return
    }
    
    if clientApplication == nil {
      clientApplication = delegate.loadClientApplication(instance: instance)
    }
    
    if let username = username, loginSettings == nil {
      loginSettings = delegate.loadLoginSettings(username: username)
    }
  }
  
  func acquireAuthenticatedClient() {
    loadStoredItems()
    
    if let loginSettings = loginSettings {
      authenticatedClient = Client(baseURL: baseUrl, accessToken: loginSettings.accessToken)
      delegate?.authenticatedClient(client: authenticatedClient!)
      return
    }
    
    let applicationPromise: Promise<ClientApplication>
    if let clientApplication = clientApplication {
      applicationPromise = Promise({ (completion) in
        completion(clientApplication)
      })
    } else {
      let clientName = delegate!.clientName()
      let request = Clients.register(clientName: clientName, redirectURI: redirectUri, scopes: scopes)
      applicationPromise = anonymousClient.run(request)
      applicationPromise.then { (clientApplication) in
        self.clientApplication = clientApplication
        self.delegate?.store(clientApplication: clientApplication, forInstance: self.instance)
      }
    }
    
    applicationPromise.then { (clientApplication) in
      // we now have an ClientApplication for sure, let's ask the client to open the browser to authentikate the user
      let url = URLComponents(string: self.baseUrl + "oauth/authorize",
                              queryItems: ["scope": self.scopes.map({ $0.rawValue }).joined(separator: " "),
                                           "client_id": clientApplication.clientID,
                                           "redirect_uri": self.redirectUri,
                                           "response_type": "code"
        ])!.url!
      TokenController.controllers.insert(self)
      self.delegate?.open(url: url)
    }
  }
  
  static func handleCallback(url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    let queryItems = components.queryDict
    let uuid = queryItems["uuid"]!!
    let code = queryItems["code"]!!
    
    let tokenController = TokenController.controllers.first(where: { $0.uuid == uuid })!
    TokenController.controllers.remove(tokenController)
    tokenController.generateAccessToken(authenticationCode: code)
  }
  
  func generateAccessToken(authenticationCode: String) {
    let app = self.clientApplication!
    let request = Login.oauth(clientID: app.clientID, clientSecret: app.clientSecret, scopes: scopes, redirectURI: redirectUri, code: authenticationCode)
    anonymousClient.run(request).then { (login) in
      let client = Client(baseURL: self.baseUrl, accessToken: login.accessToken)
      self.authenticatedClient = client
      self.delegate?.authenticatedClient(client: client)
      client.run(Accounts.currentUser()).then { (account) in
        self.delegate?.store(loginSettings: login, forUsername: account.username, instance: self.instance)
      }
    }
  }
}

extension TokenController: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
  
  public static func == (lhs: TokenController, rhs: TokenController) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}
