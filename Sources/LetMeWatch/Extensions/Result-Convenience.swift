//
//  Result-Convenience.swift
//  LetMeWatch
//

import Foundation

extension Result where Failure == Error {
    enum InvalidResultError: LocalizedError {
        /// An error thrown when the result is invalid
        case invalidResultError
        
        var errorDescription: String? {
            return "Failed to parse response. Either a success object or an error must be returned."
        }
    }
    
    /// Creates a `Result` by checking an optional success or failure type. Either the success or failure object **must** be non-nil.
    /// - Parameters:
    ///   - success: An optional object that conforms to `Success`
    ///   - failure: An optional object that conforms to `Failure`
    init(success: Success?, failure: Failure?) {
        if let success = success {
            self = .success(success)
        } else if let failure = failure {
            self = .failure(failure)
        } else {
            let error = InvalidResultError.invalidResultError
            self = .failure(error)
        }
    }
}
