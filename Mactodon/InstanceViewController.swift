// Copyright Max von Webel. All Rights Reserved.

import Atributika
import Cocoa
import MastodonKit

class InstanceViewController: NSViewController {
  var clientApplication: ClientApplication?
  let client = ValuePromise<Client?>(initialValue: nil)
  let currentUser = ValuePromise<Account?>(initialValue: nil)
  let streamingController = ValuePromise<StreamingController?>(initialValue: nil)
  var tokenController: TokenController?
  var multiFeedViewController: MultiFeedViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    client.didChange.then { [weak self] in
      self?.update()
    }
    
    client.didChange.then { [weak self] (client) in
      if let client = client {
        StreamingController.controller(client: client).then { [weak self] (controller) in
          self?.streamingController.value = controller
        }
      } else {
        self?.streamingController.value = nil
      }
    }
    
    currentUser.didChange.mainQueue.then { [weak self] (currentUser) in
      self?.view.window?.title = currentUser?.username ?? "Mactodon"
    }
    
    let multiFeedViewController = MultiFeedViewController(client: client, streamingController: streamingController)
    check(selectedFeed: multiFeedViewController.selectedFeed)
    multiFeedViewController.view.autoresizingMask = [.width, .height]
    multiFeedViewController.view.frame = view.bounds
    addChild(multiFeedViewController)
    view.addSubview(multiFeedViewController.view)
    self.multiFeedViewController = multiFeedViewController
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    
    let settings = Settings.load()
    guard let account = settings.accounts.first else {
      displayLogin()
      return
    }
    
    tokenController = TokenController(delegate: self,
                                      scopes: [.follow, .read, .write],
                                      username: account.username,
                                      instance: account.instance,
                                      protocolHandler: Bundle.main.bundleIdentifier!)
    tokenController?.acquireAuthenticatedClient()
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
    guard let client = self.client.value else {
      return
    }
    
    client.run(Accounts.currentUser()).then {
      self.currentUser.value = $0
    }
  }
  
  @IBAction func refreshFeed(_ sender: AnyObject) {
    multiFeedViewController.refresh()
  }
  
  lazy var switchMenuItems: [MultiFeedViewController.Feed: NSMenuItem] = {
    let appDelegate = AppDelegate.Shared()
    return [
      .UserTimeline: appDelegate.switchToUserTimeline,
      .LocalTimeline: appDelegate.switchToLocalTimeline,
      .FederatedTimeline: appDelegate.switchToFederatedTimeline,
      .Notifications: appDelegate.switchToNotifications
    ]
  }()
  
  func check(selectedFeed: MultiFeedViewController.Feed) {
    switchMenuItems.forEach { (element) in
      element.value.state = element.key == selectedFeed ? .on : .off
    }
  }
  
  @IBAction func switchToFeed(_ sender: NSMenuItem) {
    let feed = switchMenuItems.first { (_, value) -> Bool in
      return value == sender
    }!.key
    multiFeedViewController.selectedFeed = feed
    check(selectedFeed: feed)
  }
}

extension InstanceViewController: LoginViewControllerDelegate {
  func registered(baseURL: URL) {
    tokenController = TokenController(delegate: self, scopes: [.follow, .read, .write], instance: baseURL.host!, protocolHandler: Bundle.main.bundleIdentifier!)
    tokenController!.acquireAuthenticatedClient()
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
    
    var settings = Settings.load()
    settings.accounts = settings.accounts + [Settings.Account(username, instance)]
    settings.save()
  }
  
  func authenticatedClient(client: Client) {
    self.client.value = client
  }
  
  func clientName() -> String {
    return "Mactodon"
  }
  
  func open(url: URL) {
    NSWorkspace.shared.open(url)
  }
}
