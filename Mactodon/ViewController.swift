// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class ViewController: NSViewController {

    override func viewDidAppear() {
        displayLogin()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    lazy var loginViewController: LoginViewController = {
        return storyboard!.instantiateLoginViewController()
    }()
    
    func displayLogin() {
        presentAsSheet(loginViewController)
    }


}

