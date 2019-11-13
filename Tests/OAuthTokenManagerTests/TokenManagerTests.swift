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
    
    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      callback(.success(1))
    }, completion: { (result: ActionResult) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })
   
    wait(for: [expec], timeout: 5)
  }
  
  func testActionIsUnauthorizedAndRefreshSuccess() {
    let expec = expectation(description: "completed")
    
    let newAccessToken = "atoken-2"
    let newRefreshToken = "rtoken-2"
    
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((newAccessToken, newRefreshToken))
    }

    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }
    
    delegate.addHandlerForUpdateToken(description: "Updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, newAccessToken)
      XCTAssertEqual(refreshToken, newRefreshToken)
    }
    
    manager.withAccessToken(action: { (accessToken, callback ) in
      if accessToken == self.initialAccessToken {
        callback(.failure(.unauthorized))
      } else if accessToken == newAccessToken {
        callback(.success(1))
      }
    }, completion: { (result: Result<MockResult, AuthError<MockError>>) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }
  
  static var allTests = [
    ("testSuccessAction", testSuccessAction),
    ("testActionIsUnauthorizedAndRefreshSuccess", testActionIsUnauthorizedAndRefreshSuccess)
  ]
}
