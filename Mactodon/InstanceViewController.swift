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
  
  var tokenController: TokenController?
  
  override func viewDidLoad() {
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
      self.currentUser = $0
    }
    
    client.run(Timelines.home()).then {
      self.homeTimeline = $0
    }
  }
}

extension InstanceViewController: LoginViewControllerDelegate {
  func registered(baseURL: URL) {
    tokenController = TokenController(delegate: self, scopes: [.follow, .read, .write], instance: baseURL.host!, protocolHandler: Bundle.main.bundleIdentifier!)
    tokenController?.acquireAuthenticatedClient()
  }
}

extension InstanceViewController: TokenControllerDelegate {
  func loadClientApplication(instance: String) -> ClientApplication? {
    return try! Keychain.getClientApplication(instance: instance)
  }
  
  func loadLoginSettings(username: String, instance: String) -> LoginSettings? {
    return try! Keychain.getLoginSettings(forUser: username, instance: instance)
  }
  
  func store(clientApplication: ClientApplication, forInstance instance: String) {
    try! Keychain.set(clientApplication: clientApplication, instance: instance)
  }
  
  func store(loginSettings: LoginSettings, forUsername username: String, instance: String) {
    try! Keychain.set(loginSettings: loginSettings, forUser: username, instance: instance)
  }
  
  func authenticatedClient(client: Client) {
    self.client = client
  }
  
  func clientName() -> String {
    return "Mactodon"
  }
  
  func open(url: URL) {
    NSWorkspace.shared.open(url)
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
