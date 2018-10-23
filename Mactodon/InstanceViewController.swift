// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit


class InstanceViewController: NSViewController {
  static let baseURLKey = "BaseURL"

  @IBOutlet weak var tableView: NSTableView!
  
  var clientApplication: ClientApplication?
  var client: Client? {
    didSet {
      update()
    }
  }
  
  var currentUser: Account? {
    didSet {
      DispatchQueue.main.async {
        self.view.window?.title = self.currentUser?.username ?? "Mactodon"
      }
    }
  }
  
  var homeTimeline: [Status]? {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  var baseURL: URL?
  
  override func viewDidLoad() {
    baseURL = URL(string: UserDefaults.standard.string(forKey: InstanceViewController.baseURLKey) ?? "")
    tableView.dataSource = self
    tableView.delegate = self
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
    
    client.run(Accounts.currentUser()).then {
      self.currentUser = $0.model
    }
    
    client.run(Timelines.home()).then {
      self.homeTimeline = $0.model
    }
  }
}

extension InstanceViewController: LoginViewControllerDelegate {
  func registered(baseURL: URL, application: ClientApplication) {
    self.baseURL = baseURL
    self.clientApplication = application
    
    let url = URLComponents(string: baseURL.absoluteString + "oauth/authorize",
                            queryItems: ["scope": "read write follow",
                                         "client_id": application.clientID,
                                         "redirect_uri": Clients.redirectUri(instance: baseURL),
                                         "response_type": "code"
                                         ])!.url!
    registerAuthenticationNotification()
    NSWorkspace.shared.open(url)
  }
}

extension InstanceViewController {
  // user authentication
  static let userAuthenticatedNotification = NSNotification.Name(rawValue: "userAuthenticatedNotification")

  func registerAuthenticationNotification() {
    NotificationCenter.default.addObserver(self, selector: #selector(userAuthenticated), name: InstanceViewController.userAuthenticatedNotification, object: nil)
  }
  
  func unregisterAuthenticationNotification() {
    NotificationCenter.default.removeObserver(self, name: InstanceViewController.userAuthenticatedNotification, object: nil)
  }
  
  @objc func userAuthenticated(notification: Foundation.Notification) {
    if notification.object as! String != baseURL!.host! {
      return
    }
    
    unregisterAuthenticationNotification()
    let code = notification.userInfo!["code"] as! String
    
    let application = self.clientApplication!
    let request = Login.oauth(clientID: application.clientID, clientSecret: application.clientSecret, scopes: [.read, .write, .follow], redirectURI: Clients.redirectUri(instance: self.baseURL!), code: code)
    let client = Client(baseURL: baseURL!.absoluteString)
    client.run(request).then {
      self.client = Client(baseURL: self.baseURL!.absoluteString, accessToken: $0.model.accessToken)
    }
  }
  
  static func handleAuthentication(url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    let queryItems = components.queryDict
    let host = queryItems["host"]!!
    let code = queryItems["code"]!!
    
    NotificationCenter.default.post(name: InstanceViewController.userAuthenticatedNotification, object: host, userInfo: ["code": code])
  }
}

extension InstanceViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return homeTimeline?.count ?? 0
  }
}

extension InstanceViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let status = homeTimeline![row]
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Status"), owner: nil) as! NSTableCellView
    
    cell.textField?.stringValue = status.content
    
    return cell
  }
}
