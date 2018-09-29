// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import p2_OAuth2

extension NSStoryboard {
  func instantiateLoginViewController(context: NSWindow) -> LoginViewController {
    let viewController = instantiateController(withIdentifier: "LoginSheet") as! LoginViewController
    viewController.contextWindow = context
    return viewController
  }
}

class LoginViewController: NSViewController {
  @IBOutlet weak var instanceNameField: NSTextField!
  @IBOutlet weak var connectButton: NSButton!
  
  weak var contextWindow: NSWindow!
  
  var client: Client?
  var url: URL? {
    get {
      return URL(string: "https://\(instanceNameField.stringValue)/")
    }
  }
  
  let defaults = UserDefaults.standard
  static let instanceKey = "DefaultInstance"
  
  var loader: OAuth2DataLoader?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    instanceNameField.delegate = self
    instanceNameField.stringValue = defaults.string(forKey: LoginViewController.instanceKey) ?? ""
    connectButton.isEnabled = url != nil
  }
  
  @IBAction func cancel(_ sender: Any) {
    dismiss(nil)
  }
  
  @IBAction func connect(_ sender: Any) {
    guard let url = self.url else {
      return
    }
    
    defaults.set(instanceNameField.stringValue, forKey: LoginViewController.instanceKey)
    defaults.synchronize()
    
    Clients.withApplication(baseUrl: url.absoluteString) { (result) in
      switch result {
      case .failure(let error):
        assert(false, error.localizedDescription)
        
      case .success(let application, _):
        DispatchQueue.main.async {
          self.dismiss(nil)
        }
        
        let oauth2 = OAuth2CodeGrant(settings: [
          "client_id": application.clientID,
          "client_secret": application.clientSecret,
          "authorize_uri": "\(url.absoluteString)oauth/authorize",
          "token_uri": "\(url.absoluteString)oauth/token",
          "redirect_uris": [application.redirectURI],
          "scope": [AccessScope.read, AccessScope.write, AccessScope.follow].map({ $0.rawValue }).joined(separator: " "),
          ] as OAuth2JSON)
        oauth2.authConfig.authorizeEmbedded = true
        oauth2.authConfig.authorizeContext = self.contextWindow
        
        let loader = OAuth2DataLoader(oauth2: oauth2)
        self.loader = loader
        
        loader.perform(request: URLRequest(url: url.appendingPathComponent("/api/v1/accounts/verify_credentials")), callback: { (response) in
          print("response: \(response)")
          print("accessToken: \(String(describing: oauth2.accessToken))")
          
          let client = Client(baseURL: url.absoluteString, accessToken: oauth2.accessToken)
          
          client.run(Accounts.currentUser(), completion: { (result) in
            print("result: \(result)")
          })
        })
      }
    }
  }
}

extension LoginViewController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Cocoa.Notification) {
    guard instanceNameField as AnyObject === obj.object as AnyObject else {
      return
    }
    
    connectButton.isEnabled = url != nil
  }
}
