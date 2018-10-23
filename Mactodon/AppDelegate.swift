// Copyright Max von Webel. All Rights Reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func application(_ application: NSApplication, open urls: [URL]) {
    urls.forEach { (url) in
      InstanceViewController.handleAuthentication(url: url)
    }
  }
}
