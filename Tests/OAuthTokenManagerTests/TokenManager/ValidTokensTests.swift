import XCTest
@testable import OAuthTokenManager

final class ValidTokensTests: XCTestCase {
  
  var initialAccessToken: AccessToken = "atoken-1"
  var initialRefreshToken: RefreshToken = "rtoken-1"
  var manager: TokenManager<MockDelegate>!
  var delegate: MockDelegate!
  
  override func setUp() {
    manager = TokenManager(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
    delegate = MockDelegate(expectation: expectation(description:))
    manager.delegate = delegate

    // access token is fine
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      return false
    }
  }
  
  func testActionSuccess() {
    let expec = expectation(description: "completed")
    
    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      // we will just return a result
      callback(.success(1))
    }, completion: { (result: ActionResult) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })
   
    wait(for: [expec] + delegate.allExpectations, timeout: 5)
  }

  func testActionError() {
    let expec = expectation(description: "completed")

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      callback(.failure(.other(MockError())))
    }, completion: { (result: ActionResult) in
      if case let .failure(.other(resultError)) = result {
        XCTAssertNotNil(resultError as? MockError)
        expec.fulfill()
      }
    })

    wait(for: [expec] + delegate.allExpectations, timeout: 5)
  }

  func testActionShouldBeRunWithoutRefreshToken() {
    let expec = expectation(description: "completed")

    // we expect to receive the updated tokens for removing the refresh token
    delegate.addHandlerForUpdateToken(description: "Updated Refresh Token") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      XCTAssertNil(refreshToken)
    }

    manager.removeRefreshToken()

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      callback(.success(1))
    }, completion: { (result: ActionResult) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: [expec] + delegate.allExpectations, timeout: 5)
  }
}
