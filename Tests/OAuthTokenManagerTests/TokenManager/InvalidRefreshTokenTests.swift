//
//  InvalidRefreshTokenTests.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 23/11/2019.
//

import XCTest

final class InvalidRefreshTokenTests: XCTestCase {

  let initialAccessToken: AccessToken = "atoken-1"
  let initialRefreshToken: RefreshToken = "rtoken-1"
  let newAccessToken = "atoken-2"
  let newRefreshToken = "rtoken-2"
  var manager: TokenManager<MockDelegate>!
  var delegate: MockDelegate!

  override func setUp() {
    manager = TokenManager(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
    delegate = MockDelegate(expectation: expectation(description:))
    manager.delegate = delegate

    // we mark the first access token as expired
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      return true
    }

    // we expect that the access token is removed and the refresh token is still the same
    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }
  }

  func testRefreshingTokenReturnsError() {
    let expec = expectation(description: "completed")

    // see setup for common assertions

    // our refresh call returns an error
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .failure(.other(MockError()))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTFail("Should not have been called")
    }, completion: { (result: Result<MockResult, AuthError>) in
      if case let .failure(.other(error)) = result {
        XCTAssertNotNil(error as? MockError)
        expec.fulfill()
      }
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }

  func testRefreshingTokenReturnsErrorWithMultipleCalls() {
    let withAccessExpect1 = expectation(description: "completed withAccessToken #2")
    let withAccessExpect2 = expectation(description: "completed withAccessToken #2")

    // see setup for common assertions

    // our refresh call returns an error
    // should only be called once
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .failure(.other(MockError()))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTFail("Should not have been called")
    }, completion: { (result: Result<MockResult, AuthError>) in
      if case let .failure(.other(error)) = result {
        XCTAssertNotNil(error as? MockError)
        withAccessExpect1.fulfill()
      }
    })

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTFail("Should not have been called")
    }, completion: { (result: Result<MockResult, AuthError>) in
      if case let .failure(.other(error)) = result {
        XCTAssertNotNil(error as? MockError)
        withAccessExpect2.fulfill()
      }
    })

    wait(for: delegate.allExpectations + [withAccessExpect1, withAccessExpect2], timeout: 5)
  }

  func testLoginWithSuccess() {
    let expec = expectation(description: "completed")

    // see setup for common assertions

    // our refresh call returns an error
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .failure(.unauthorized)
    }

    // we expect that the tokens are removed
    delegate.addHandlerForUpdateToken(description: "Removed tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, nil)
    }

    delegate.addHandlerForRequireLogin(description: "Requires login") {
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    // we expect that the tokens are updated
    delegate.addHandlerForUpdateToken(description: "Received updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(refreshToken, self.newRefreshToken)
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      callback(.success(1))
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }

  func testLoginWithFailure() {
    let expec = expectation(description: "completed")

    // see setup for common assertions

    // our refresh call returns an error
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .failure(.unauthorized)
    }

    // we expect that the tokens are removed
    delegate.addHandlerForUpdateToken(description: "Removed tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, nil)
    }

    // we'll let the login fail
    delegate.addHandlerForRequireLogin(description: "Requires login") {
      return .failure(.other(MockError()))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTFail("Should never be called")
    }, completion: { (result: Result<MockResult, AuthError>) in
      if case let .failure(.other(error)) = result, let _ = error as? MockError {
        expec.fulfill()
      }
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }
}

