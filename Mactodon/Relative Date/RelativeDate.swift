// Copyright Max von Webel. All Rights Reserved.

import Foundation

extension TimeInterval {
  func relativeString(useSeconds: Bool = true) -> String {
    switch self {
    case 0..<60:
      if useSeconds {
        return "\(Int(self))s"
      } else {
        return "now"
      }
    case 60..<3600:
      return "\(Int(self / 60))m"
    case 3600..<(3600*48):
      return "\(Int(self / 3600))h"
    default:
      return "\(Int(self / (3600 * 24)))d"
    }
  }
}
