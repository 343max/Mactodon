// Copyright Max von Webel. All Rights Reserved.

import Foundation

protocol UntypedPromise {
    typealias UntypedThenCall = () -> Void
    typealias ErrorCall = (_ error: Error) -> Void

    @discardableResult func then(_ completion: @escaping UntypedThenCall) -> Self
    @discardableResult func fail(_ failedCompletion: @escaping ErrorCall) -> Self
    func `throw`(error: Error)
}

class Promise<T> : UntypedPromise {
    typealias CompletionCallback = (_ result: T) -> Void
    typealias ThenCall = (_ result: T) -> Void

    public private(set) var error: Error?
    public private(set) var result: T?

    var fulfilled: Bool {
        get {
            return result != nil
        }
    }

    var failed: Bool {
        get {
            return error != nil
        }
    }

    var thenCalls: [ThenCall] = []
    var errorCalls: [ErrorCall] = []

    convenience init(_ setup: @escaping (_ complete: @escaping CompletionCallback) throws -> Void) {
        let fullSetup = { (_ complete: @escaping CompletionCallback, _ promise: Promise) throws -> Void in
            try setup(complete)
        }

        self.init(fullSetup)
    }

    init(_ setup: (_ complete: @escaping CompletionCallback, _ promise: Promise) throws -> Void) {
        do {
            try setup({ (result) in
                self.result = result

                self.handleThens()
            }, self)
        } catch {
            self.error = error

            self.handleFails()
        }
    }

    private func handleThens() {
        guard let result = self.result else {
            return
        }

        for thenCall in thenCalls {
            thenCall(result)
        }

        thenCalls = []
    }

    private func handleFails() {
        guard let error = self.error else {
            return
        }

        for errorCall in errorCalls {
            errorCall(error)
        }

        errorCalls = []
    }

    func `throw`(error: Error) {
        self.error = error

        handleFails()
    }
    
    func fulfill(_ result: T) {
        assert(!self.fulfilled, "promise already fulfilled")
        self.result = result
        self.handleThens()
    }
    
    @discardableResult func then(_ completion: @escaping ThenCall) -> Self {
        thenCalls.append(completion)

        handleThens()

        return self
    }

    @discardableResult func then(_ completion: @escaping UntypedPromise.UntypedThenCall) -> Self {
        self.then { (_) in
            completion()
        }

        return self
    }

    @discardableResult func fail(_ failedCompletion: @escaping ErrorCall) -> Self {
        errorCalls.append(failedCompletion)

        handleFails()

        return self
    }

    func map<U>(_ mapping: @escaping (_ result: T) -> U) -> Promise<U> {
        return Promise<U>({ (completion) in
            self.then({ (result) in
                completion(mapping(result))
            })
        })
    }
}

func allDone<T>(_ promiseContainer: T) -> Promise<T> {
    return Promise<T>({ (completion, allDonePromise) in
        let promises: [UntypedPromise]
        if let dict = promiseContainer as? [AnyHashable: Any] {
            promises = dict.values.compactMap { $0 as? UntypedPromise }
        } else {
            promises = Mirror(reflecting: promiseContainer).children.compactMap { $0.value as? UntypedPromise }
        }

        var remaining = promises.count
        for promise in promises {
            promise.then {
                remaining -= 1
                if remaining == 0 {
                    completion(promiseContainer)
                }
            }

            promise.fail { (error) in
                allDonePromise.throw(error: error)
            }
        }
    })
}
