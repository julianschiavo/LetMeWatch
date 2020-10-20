//
//  URL-SignedScheme.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import Foundation

extension URL {
    /// The static value of the network scheme used for requests handled by this package, required to use `AVAssetResourceLoaderDelegate`.
    private static let SIGNED_SCHEME = "signed"
    
    /// The static value of the default HTTPS scheme.
    private static let DEFAULT_SCHEME = "https"
    
    /// The URL with the `signed` scheme
    var withSignedScheme: URL {
        withScheme(URL.SIGNED_SCHEME)
    }
    
    /// The URL with the default (`https`) scheme
    var withDefaultScheme: URL {
        withScheme(URL.DEFAULT_SCHEME)
    }
    
    /// Replaces the URL's scheme
    /// - Parameter scheme: The new scheme
    /// - Returns: The URL using the new scheme
    private func withScheme(_ scheme: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.scheme = scheme
        return components?.url ?? self
    }
}
