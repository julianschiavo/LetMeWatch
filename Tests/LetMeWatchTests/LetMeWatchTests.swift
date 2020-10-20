import XCTest
@testable import LetMeWatch

final class LetMeWatchTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LetMeWatch().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
