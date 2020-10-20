//
//  AVAssetResourceLoadingContentInformationRequest-Update.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation
import UniformTypeIdentifiers

extension AVAssetResourceLoadingContentInformationRequest {
    /// Updates the content info request with the necessary information gleaned from a server response
    /// - Parameter response: The server response
    func update(with response: URLResponse) {
        if let mimeType = response.mimeType,
           let utType = UTType(mimeType: mimeType) {
            contentType = utType.identifier
        }
        
        if let length = response.expectedContentLength {
            contentLength = Int64(length)
        }
        
        isByteRangeAccessSupported = response.isByteRangeAccessSupported
    }
}
