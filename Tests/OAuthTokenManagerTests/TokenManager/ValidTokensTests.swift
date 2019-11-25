import XCTest
@testable import OAuthTokenManager

final class ValidTokensTests: XCTestCase {
  
  var initialAccessToken: AccessToken = "atoken-1"
  var initialRefreshToken: RefreshToken = "rtoken-1"
  var manager: TokenManager<MockDelegate, MockStorage>!
  var storage: MockStorage!
  var delegate: MockDelegate!
  
  override func setUp() {
    storage = MockStorage(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
    manager = TokenManager(storage: storage)
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
    storage.refreshToken = nil

    let expec = expectation(description: "completed")

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.initialAccessToken)
      callback(.success(1))
    }, completion: { (result: ActionResult) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: [expec] + delegate.allExpectations, timeout: 5)
  }

  func testActionOnOtherThread() {
    let expec = expectation(description: "completed")

    DispatchQueue.global().async {
      self.manager.withAccessToken(action: { (accessToken, callback ) in
        XCTAssertTrue(Thread.isMainThread)
        DispatchQueue.global().async {
          callback(.success(1))
        }
      }, completion: { (result: ActionResult) in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(try? result.get(), 1)
        expec.fulfill()
      })
    }

    wait(for: [expec] + delegate.allExpectations, timeout: 5)
  }
}
