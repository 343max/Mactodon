// Copyright Max von Webel. All Rights Reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var switchToUserTimeline: NSMenuItem!
  @IBOutlet var switchToLocalTimeline: NSMenuItem!
  @IBOutlet var switchToFederatedTimeline: NSMenuItem!
  @IBOutlet var switchToNotifications: NSMenuItem!
  
  func application(_ application: NSApplication, open urls: [URL]) {
    urls.forEach { (url) in
      TokenController.handleCallback(url: url)
    }
  }
  
  static func Shared() -> AppDelegate {
    return NSApplication.shared.delegate as! AppDelegate
  }
}
