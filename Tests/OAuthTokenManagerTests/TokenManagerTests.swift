import XCTest
@testable import OAuthTokenManager

final class OAuthTokenManagerTests: XCTestCase {
  
  var initialAccessToken: AccessToken = "atoken-1"
  var initialRefreshToken: RefreshToken = "rtoken-1"
  var manager: TokenManager<MockDelegate>!
  var delegate: MockDelegate!
  
  override func setUp() {
    manager = TokenManager(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
    delegate = MockDelegate(expectation: expectation(description:))
    manager.delegate = delegate
  }
  
  func testSuccessAction() {
    let expec = expectation(description: "completed")

    // access token is fine
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      return false
    }
    
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
  
  func testActionIsUnauthorizedAndRefreshSuccess() {
    let expec = expectation(description: "completed")
    
    let newAccessToken = "atoken-2"
    let newRefreshToken = "rtoken-2"

    // when we return the token is NOT expired. So the action will be run and we will return a .notAuthorized in the action
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      return false
    }

    // we expect that the access token is removed and the refresh token is still the same
    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }

    // we expect to be requested to refresh the accesstoken
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((newAccessToken, newRefreshToken))
    }

    // we expect to receive the updated tokens
    delegate.addHandlerForUpdateToken(description: "Updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, newAccessToken)
      XCTAssertEqual(refreshToken, newRefreshToken)
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      if accessToken == self.initialAccessToken {
        // first attempt
        callback(.failure(.unauthorized))
      } else if accessToken == newAccessToken {
        // attempt with updated token
        callback(.success(1))
      }
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }

  func testAccessTokenExpiredAndRefreshSuccess() {
    let expec = expectation(description: "completed")

    let newAccessToken = "atoken-2"
    let newRefreshToken = "rtoken-2"

    // when we return the token is expored
    delegate.addHandlerForShouldExpire(description: "Should expire") { (accessToken) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      return true
    }

    // we expect that the access token is removed and the refresh token is still the same
    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }

    // we expect to be requested to refresh the accesstoken
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((newAccessToken, newRefreshToken))
    }

    // we expect to receive the updated tokens
    delegate.addHandlerForUpdateToken(description: "Updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, newAccessToken)
      XCTAssertEqual(refreshToken, newRefreshToken)
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, newAccessToken)
      callback(.success(1))
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }
  
}
