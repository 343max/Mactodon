// Copyright Max von Webel. All Rights Reserved.

import Foundation
import MastodonKit

extension Client {
  struct Response<Model> {
    let model: Model
    let pagination: Pagination?
  }

  func run<Model>(_ request: Request<Model>) -> Promise<Response<Model>> {
    return Promise({ (completion, promise) in
      self.run(request, completion: { (result) in
        switch result {
        case .failure(let error):
          promise.throw(error: error)
        case .success(let model, let pagination):
          completion(Response(model: model, pagination: pagination))
        }
      })
    })
  }
}
