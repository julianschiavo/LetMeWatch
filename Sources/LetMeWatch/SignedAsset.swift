//
//  SignedAsset.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation

/// A concrete subclass of `AVURLAsset` that represents an asset loaded from a remote URL using a client certificate.
public class SignedAsset: AVURLAsset {
    /// The asset's resource loader delegate, which handles requests made by the resource loader using a client certificate.
    private var resourceLoaderDelegate: ResourceLoaderDelegate!
    
    /// Initializes an asset that models the media resource found at the specified URL.
    /// - Parameters:
    ///   - url: A URL that references the media to be represented by the asset.
    ///   - errorHandler: Called when an error occurs
    public init(url: URL, errorHandler: ((Error) -> Void)? = nil) {
        let schemedURL = url.withSignedScheme
        super.init(url: schemedURL, options: nil)
        
        resourceLoaderDelegate = ResourceLoaderDelegate(for: self, errorHandler: errorHandler)
    }
}
