//
//  ByteRange.swift
//  LetMeWatch
//
//  Adapted from https://github.com/jaredsinclair/sodes-audio-example
//

import Foundation

/// A range of bytes
typealias ByteRange = Range<Int>

extension ByteRange where Bound: Comparable {
    /// The last valid index for the range
    var lastValidIndex: Bound {
        return upperBound - 1
    }
}
