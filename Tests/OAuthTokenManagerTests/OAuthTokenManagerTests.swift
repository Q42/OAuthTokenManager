import XCTest
@testable import OAuthTokenManager

final class OAuthTokenManagerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OAuthTokenManager().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
