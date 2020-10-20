//
//  URLRequest-ByteRange.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import Foundation

extension URLRequest {
    /// The static name of the `Range` header
    private var RANGE_HEADER: String { "Range" }
    
    /// The value of the `Range` header
    private var contentRangeHeader: String? {
        value(forHTTPHeaderField: RANGE_HEADER)
    }
    
    /// The byte range of the request
    var byteRange: ByteRange? {
        guard let header = contentRangeHeader else { return nil }
        let values = header.replacingOccurrences(of: "bytes=", with: "").split(separator: "-").compactMap(String.init).compactMap(Int.init)
        guard values.count == 2 else { return nil }
        return values[0] ..< (values[1] + 1)
    }
    
    // MARK: - Methods
    
    /// Sets the byte range of the request
    /// - Parameter byteRange: The byte range as a range of integers
    mutating func setByteRange(_ byteRange: ByteRange) {
        let header = "bytes=\(byteRange.lowerBound)-\(byteRange.upperBound)"
        setValue(header, forHTTPHeaderField: RANGE_HEADER)
    }
}
