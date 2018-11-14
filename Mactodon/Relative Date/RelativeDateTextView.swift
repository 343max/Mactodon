// Copyright Max von Webel. All Rights Reserved.

import Cocoa

class RelativeDateTextView: NSTextView {
  var showSeconds = false
  var date: Date? {
    didSet {
      updateDate()
      updateRelativeDate()
    }
  }
  
  var shouldUpdate: Bool = false {
    didSet {
      if shouldUpdate {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
          self?.updateRelativeDate()
        })
      } else {
        self.timer?.invalidate()
        self.timer = nil
      }
    }
  }
  
  var timer: Timer?
  
  static var dateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter
  }()
  
  func updateDate() {
    guard let date = date else {
      toolTip = nil
      return
    }
    
    toolTip = RelativeDateTextView.dateFormatter.string(from: date)
  }
  
  func updateRelativeDate() {
    guard let date = date else {
      string = ""
      return
    }
    
    string = Date().timeIntervalSince(date).relativeString(useSeconds: showSeconds)
    setAlignment(.right, range: NSRange(location: 0, length: string.count))
  }
  
  deinit {
    shouldUpdate = false
  }
}
