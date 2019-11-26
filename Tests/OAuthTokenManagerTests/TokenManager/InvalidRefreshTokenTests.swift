//
//  InvalidRefreshTokenTests.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 23/11/2019.
//

import XCTest
@testable import OAuthTokenManager

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
  }

  func testRefreshingTokenReturnsError() {
    let expec = expectation(description: "completed")

    // see setup for common assertions

    // our refresh call returns an error
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      return .failure(.other(MockError()))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTFail("Should not have been called")
    }, completion: { (result: Result<MockResult, AuthError>) in
      if case let .failure(.other(error)) = result {
        XCTAssertNotNil(error as? MockError)
        XCTAssertEqual(self.manager.state, .authorized)
        XCTAssertNil(self.manager.accessToken)
        XCTAssertNotNil(self.manager.refreshToken)
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
      return .failure(.unauthorized)
    }

    delegate.addHandlerForRequireAuthorization(description: "Requires login") {
      XCTAssertEqual(self.manager.state, .reauthorizing)
      self.manager.authorize(accessToken: self.newAccessToken, refreshToken: self.newRefreshToken)
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(self.manager.state, .authorized)
      callback(.success(1))
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      XCTAssertEqual(self.manager.state, .authorized)
      XCTAssertEqual(self.manager.accessToken, self.newAccessToken)
      XCTAssertEqual(self.manager.refreshToken, self.newRefreshToken)      
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

    // we'll let the login fail
    delegate.addHandlerForRequireAuthorization(description: "Requires login") {
      self.manager.abortAuthorization(with: .other(MockError()))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTFail("Should never be called")
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(self.manager.state, .unauthorized)
      XCTAssertNil(self.manager.accessToken)
      XCTAssertNil(self.manager.refreshToken)
      if case let .failure(.other(error)) = result, let _ = error as? MockError {
        expec.fulfill()
      }
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }
}

