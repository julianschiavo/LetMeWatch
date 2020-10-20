//
//  URLResponse-Info.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import Foundation

extension URLResponse {
    
    // MARK: - Accept Ranges
    
    /// The static name of the `Accept-Ranges` header
    private var ACCEPT_RANGES_HEADER: String { "Accept-Ranges" }
    
    /// The value of the `Accept-Ranges` header
    private var acceptRangesHeader: String? {
        guard let response = self as? HTTPURLResponse else { return nil }
        return response.value(forHTTPHeaderField: ACCEPT_RANGES_HEADER)
    }
    
    /// Whether the response suggests that the server supports accessing data based on byte ranges
    var isByteRangeAccessSupported: Bool {
        guard let header = acceptRangesHeader else { return false }
        return header == "bytes"
    }
    
    // MARK: - Content Range
    
    /// The static name of the `Content-Range` header
    private var CONTENT_RANGE_HEADER: String { "Content-Range" }
    
    /// The value of the `Content-Range` header
    private var contentRangeHeader: String? {
        guard let response = self as? HTTPURLResponse else { return nil }
        return response.value(forHTTPHeaderField: CONTENT_RANGE_HEADER)
    }
    
    /// Whether the response is for a set byte range
    var containsByteRange: Bool {
        byteRange != nil
    }
    
    /// The byte range of the response
    var byteRange: ByteRange? {
        guard let header = contentRangeHeader,
              let initialSection = header.split(separator: "/").first
        else { return nil }
        
        let values = initialSection.replacingOccurrences(of: "bytes ", with: "").split(separator: "-").compactMap(String.init).compactMap(Int.init)
        guard values.count == 2 else { return nil }
        return values[0] ..< (values[1] + 1)
    }
    
    /// The expected total content length of the resource
    var expectedContentLength: Int? {
        guard let header = contentRangeHeader,
              let initialSection = header.split(separator: "/").last
        else { return nil }
        return Int(initialSection)
    }
    
    // MARK: - Content Length
    
    /// The static name of the `Content-Length` header
    private var CONTENT_LENGTH_HEADER: String { "Content-Length" }
    
    /// The length of the response content
    var contentLength: Int? {
        guard let response = self as? HTTPURLResponse,
              let value = response.value(forHTTPHeaderField: CONTENT_LENGTH_HEADER) else { return nil }
        return Int(value)
    }
}
