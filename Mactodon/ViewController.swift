// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        displayLogin()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    lazy var loginViewController: LoginViewController = {
        let loginViewController = storyboard!.instantiateController(withIdentifier: "LoginSheet") as! LoginViewController
        return loginViewController
    }()
    
    func displayLogin() {
        presentAsSheet(loginViewController)
    }


}

