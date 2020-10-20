//
//  Request.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import AVFoundation

/// An abstract representation of a request from an `AVAssetResourceLoader`
protocol Request: class {
    var resourceURL: URL { get }
    var avRequest: AVAssetResourceLoadingRequest { get }
    func start()
    func cancel()
}
