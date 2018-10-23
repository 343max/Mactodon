// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

extension NSStoryboard {
  func instantiateLoginViewController() -> LoginViewController {
    return instantiateController(withIdentifier: "LoginSheet") as! LoginViewController
  }
}

protocol LoginViewControllerDelegate: NSObjectProtocol {
  func registered(baseURL: URL)
}

class LoginViewController: NSViewController {
  @IBOutlet weak var instanceNameField: NSTextField!
  @IBOutlet weak var connectButton: NSButton!
  @IBOutlet weak var errorLabel: NSTextField!
  
  weak var delegate: LoginViewControllerDelegate?
  
  var client: Client?
  var url: URL? {
    get {
      return URL(string: "https://\(instanceNameField.stringValue)/")
    }
  }
  
  let defaults = UserDefaults.standard
  static let instanceKey = "DefaultInstance"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    errorLabel.isHidden = true
    
    instanceNameField.delegate = self
    instanceNameField.stringValue = defaults.string(forKey: LoginViewController.instanceKey) ?? ""
    connectButton.isEnabled = url != nil
  }
  
  override func viewDidAppear() {
    assert(delegate != nil)
  }
  
  @IBAction func cancel(_ sender: Any) {
    dismiss(nil)
  }
  
  @IBAction func connect(_ sender: Any) {
    guard let baseURL = self.url else {
      return
    }
    
    self.errorLabel.isHidden = true
    
    defaults.set(baseURL.host, forKey: LoginViewController.instanceKey)
    defaults.synchronize()
    
    delegate!.registered(baseURL: baseURL)
    dismiss(nil)
  }
}

extension LoginViewController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Cocoa.Notification) {
    guard instanceNameField as AnyObject === obj.object as AnyObject else {
      return
    }
    
    connectButton.isEnabled = url != nil && instanceNameField.stringValue.count > 2
  }
}
