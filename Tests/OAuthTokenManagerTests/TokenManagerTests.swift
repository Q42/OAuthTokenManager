import XCTest
@testable import OAuthTokenManager

final class OAuthTokenManagerTests: XCTestCase {
  
  var initialAccessToken: AccessToken = "atoken-1"
  var initialRefreshToken: RefreshToken = "rtoken-1"
  var manager: TokenManager<AccessToken, RefreshToken, MockError>!
  
  override func setUp() {
    manager = TokenManager(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
    manager.didRequireLogin = { _ in
      XCTFail("didRequireLogin should not be called")
    }
    manager.didUpdateTokens = { (_, _) in
      XCTFail("didUpdateTokens should not be called")
    }
    manager.didRequireRefresh = { (_, _) in
      XCTFail("didRequireRefresh should not be called")
    }
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
    let didUpdateTokens1Expec = expectation(description: "didUpdateTokens first")
    let didUpdateTokens2Expec = expectation(description: "didUpdateTokens second")
    let didRequireRefreshExpec = expectation(description: "didRequireRefresh")
    
    manager.didRequireRefresh = { (refreshToken, completion) in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      completion(.success(("atoken-2", "rtoken-2")))
      didRequireRefreshExpec.fulfill()
    }
    
    // should be called after we have new tokens
    let didUpdateTokensCallback2: (AccessToken?, RefreshToken?) -> Void = { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, "atoken-2")
      XCTAssertEqual(refreshToken, "rtoken-2")
      didUpdateTokens2Expec.fulfill()
    }
    
    // should be called after the access token has been invalidated
    let didUpdateTokensCallback1: (AccessToken?, RefreshToken?) -> Void = { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, "rtoken-1")
      self.manager.didUpdateTokens = didUpdateTokensCallback2
      didUpdateTokens1Expec.fulfill()
    }
       
    manager.didUpdateTokens = didUpdateTokensCallback1
     
    manager.withAccessToken(action: { (accessToken, callback ) in
      if accessToken == "atoken-1" {
        callback(.failure(.unauthorized))
      } else if accessToken == "atoken-2" {
        callback(.success(1))
      }
    }, completion: { (result: Result<MockResult, AuthError<MockError>>) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })
    
     wait(for: [expec, didUpdateTokens1Expec, didUpdateTokens2Expec, didRequireRefreshExpec], timeout: 5)
  }
  
  static var allTests = [
    ("testSuccessAction", testSuccessAction),
    ("testActionIsUnauthorizedAndRefreshSuccess", testActionIsUnauthorizedAndRefreshSuccess)
  ]
}

enum MockError: Error {
  case unknown
}
typealias AccessToken = String
typealias RefreshToken = String
typealias MockResult = Int
typealias ActionResult = Result<MockResult, AuthError<MockError>>
