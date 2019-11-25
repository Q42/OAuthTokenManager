//
//  InvalidAccessTokenTests.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 23/11/2019.
//

import XCTest
@testable import OAuthTokenManager

final class InvalidAccessTokenTests: XCTestCase {

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
  }

  func testActionIsUnauthorizedAndRefreshSuccess() {
    let expec = expectation(description: "completed")

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
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    // we expect to receive the updated tokens
    delegate.addHandlerForUpdateToken(description: "Updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(refreshToken, self.newRefreshToken)
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      if accessToken == self.initialAccessToken {
        // first attempt
        callback(.failure(.unauthorized))
      } else if accessToken == self.newAccessToken {
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
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    // we expect to receive the updated tokens
    delegate.addHandlerForUpdateToken(description: "Updated tokens") { (accessToken, refreshToken) in
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

  func testNoAccessTokenAndRefreshSuccess() {
    let expec = expectation(description: "completed")

    // we expect that the access token is removed by calling removeAccessToken
    // and the refresh token is still the same
    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }

    // we expect to be requested to refresh the accesstoken
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    // we expect to receive the updated tokens
    delegate.addHandlerForUpdateToken(description: "Updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(refreshToken, self.newRefreshToken)
    }

    // lets clear the access token
    manager.removeAccessToken()

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      callback(.success(1))
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      expec.fulfill()
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }

  func testInvalidAccessTokenWithMultipleCalls() {
    let withAccessExpect1 = expectation(description: "completed withAccessToken #1")
    let withAccessExpect2 = expectation(description: "completed withAccessToken #2")

    // we mark the first access token as expired
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      return true
    }

    // we expect that the access token is removed and the refresh token is still the same
    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }

    // our refresh call returns a new token
    // should only be called once
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
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
      withAccessExpect1.fulfill()
    })

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      callback(.success(2))
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 2)
      withAccessExpect2.fulfill()
    })

    wait(for: delegate.allExpectations + [withAccessExpect1, withAccessExpect2], timeout: 5)
  }


  func testMultipleCallsOnOtherThread() {
    let withAccessExpect1 = expectation(description: "completed withAccessToken #1")
    let withAccessExpect2 = expectation(description: "completed withAccessToken #2")

    // we mark the first access token as expired
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      return true
    }

    // we expect that the access token is removed and the refresh token is still the same
    delegate.addHandlerForUpdateToken(description: "Remove accesstoken") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, nil)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
    }

    // our refresh call returns a new token
    // should only be called once
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    // we expect that the tokens are updated
    delegate.addHandlerForUpdateToken(description: "Received updated tokens") { (accessToken, refreshToken) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(refreshToken, self.newRefreshToken)
    }

    DispatchQueue.global().async {
      self.manager.withAccessToken(action: { (accessToken, callback ) in
        XCTAssertTrue(Thread.isMainThread)
        DispatchQueue.global().async {
          callback(.success(1))
        }
      }, completion: { (result: ActionResult) in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(try? result.get(), 1)
        withAccessExpect1.fulfill()
      })
    }

    DispatchQueue.global().async {
      self.manager.withAccessToken(action: { (accessToken, callback ) in
        XCTAssertTrue(Thread.isMainThread)
        DispatchQueue.global().async {
          callback(.success(2))
        }
      }, completion: { (result: ActionResult) in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(try? result.get(), 2)
        withAccessExpect2.fulfill()
      })
    }

    wait(for: [withAccessExpect1, withAccessExpect2] + delegate.allExpectations, timeout: 5)
  }
}

