//
//  AVResourceLoadingDataRequest-Info.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation

extension AVAssetResourceLoadingDataRequest {
    /// The byte range requested
    var byteRange: ByteRange {
        let lowerBound = Int(requestedOffset)
        let upperBound = Int(lowerBound + requestedLength - 1)
        return lowerBound ..< upperBound
    }
}
