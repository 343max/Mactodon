// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Client {
  func successfullRun<Model>(_ request: Request<Model>, completion: @escaping (_ value: Model, _ pagination: Pagination?) -> Void) {
    run(request) { (result) in
      switch result {
      case .failure(let error):
        assert(false, "unexpected error: \(error.localizedDescription)")
      case .success(let model, let pagination):
        completion(model, pagination)
      }
    }
  }
}
