// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

extension NSStoryboard {
    func instantiateLoginViewController() -> LoginViewController {
        return instantiateController(withIdentifier: "LoginSheet") as! LoginViewController
    }
}

class LoginViewController: NSViewController {
    @IBOutlet weak var instanceNameField: NSTextField!
    @IBOutlet weak var connectButton: NSButton!
    
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
        
        let client = Client(baseURL: url.absoluteString)
        
        let request = Clients.register(clientName: "Mactodon", scopes: [.read, .write, .follow])
        
        client.run(request) { (result) in
            switch result {
            case .success(let application, _):
                print("id: \(application.id)")
                print("redirect uri: \(application.redirectURI)")
                print("client id: \(application.clientID)")
                print("client secret: \(application.clientSecret)")
                DispatchQueue.main.async {
                    self.dismiss(nil)
                }
            case .failure(let error):
                assert(false, error.localizedDescription)
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
