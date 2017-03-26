import XCTest
@testable import vaporize

class vaporizeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(vaporize().text, "Hello, World!")
    }


    static var allTests : [(String, (vaporizeTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
