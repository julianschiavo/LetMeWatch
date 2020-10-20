import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LetMeWatchTests.allTests),
    ]
}
#endif
