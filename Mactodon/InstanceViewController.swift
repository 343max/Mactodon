// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import p2_OAuth2

class InstanceViewController: NSViewController {
  static let baseURLKey = "BaseURL"

  var client: Client? {
    didSet {
      update()
    }
  }
  
  var currentUser: Account? {
    didSet {
      DispatchQueue.main.async {
        self.view.window?.title = self.currentUser?.displayName ?? "Mactodon"
      }
    }
  }
  
  var baseURL: URL?
  var loader: OAuth2DataLoader?
  
  override func viewDidLoad() {
    baseURL = URL(string: UserDefaults.standard.string(forKey: InstanceViewController.baseURLKey) ?? "")
  }
  
  override func viewDidAppear() {
    displayLogin()
  }
  
  lazy var loginViewController: LoginViewController = {
    let vc = storyboard!.instantiateLoginViewController()
    vc.delegate = self
    return vc
  }()
  
  func displayLogin() {
    presentAsSheet(loginViewController)
  }
  
  func update() {
    guard let client = self.client else {
      return
    }
    
    client.successfullRun(Accounts.currentUser()) { (user, _) in self.currentUser = user }
  }
}

extension InstanceViewController: LoginViewControllerDelegate {
  func registered(baseURL: URL, application: ClientApplication) {
    self.baseURL = baseURL
    
    let oauth2 = OAuth2CodeGrant(baseURL: baseURL, application: application)
    
    if let accessToken = oauth2.accessToken {
      client = Client(baseURL: baseURL.absoluteString, accessToken: accessToken)
    } else {
      oauth2.authConfig.authorizeEmbedded = true
      oauth2.authConfig.authorizeContext = view.window
      
      let loader = OAuth2DataLoader(oauth2: oauth2)
      self.loader = loader
      
      let url = baseURL.appendingPathComponent("/api/v1/accounts/verify_credentials")
      
      loader.perform(request: URLRequest(url: url), callback: { (response) in
        assert(oauth2.accessToken != nil)
        self.client = Client(baseURL: baseURL.absoluteString, accessToken: oauth2.accessToken!)
      })
    }
  }
}
