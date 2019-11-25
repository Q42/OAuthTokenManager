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
  var manager: TokenManager<MockDelegate, MockStorage>!
  var storage: MockStorage!
  var delegate: MockDelegate!

  override func setUp() {
    storage = MockStorage(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
    manager = TokenManager(storage: storage)
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

    // we expect to be requested to refresh the accesstoken
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertNil(self.storage.accessToken)
      XCTAssertEqual(self.manager.state, .refreshing)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      if accessToken == self.initialAccessToken {
        // we'll mock that the api returns unauthorized
        callback(.failure(.unauthorized))
      } else if accessToken == self.newAccessToken {
        // attempt with updated token
        XCTAssertEqual(self.manager.state, .authorized)
        callback(.success(1))
      }
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      XCTAssertEqual(self.manager.state, .authorized)
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

    // we expect to be requested to refresh the accesstoken
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertNil(self.storage.accessToken)
      XCTAssertEqual(self.manager.state, .refreshing)
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      if accessToken == self.initialAccessToken {
        // we'll mock that the api returns unauthorized
        callback(.failure(.unauthorized))
      } else if accessToken == self.newAccessToken {
        // attempt with updated token
        XCTAssertEqual(self.manager.state, .authorized)
        callback(.success(1))
      }
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      XCTAssertEqual(self.manager.state, .authorized)
      expec.fulfill()
    })

    wait(for: delegate.allExpectations + [expec], timeout: 5)
  }

  func testNoAccessTokenAndRefreshSuccess() {
    let expec = expectation(description: "completed")

    // lets clear the access token
    storage.accessToken = nil

    // we expect to be requested to refresh the accesstoken
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      return .success((self.newAccessToken, self.newRefreshToken))
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

  func testInvalidAccessTokenWithMultipleCalls() {
    let withAccessExpect1 = expectation(description: "completed withAccessToken #1")
    let withAccessExpect2 = expectation(description: "completed withAccessToken #2")

    // we mark the first access token as expired
    delegate.addHandlerForShouldExpire(description: "Should not expire") { (accessToken) in
      return true
    }

    // our refresh call returns a new token
    // should only be called once
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      XCTAssertEqual(refreshToken, self.initialRefreshToken)
      return .success((self.newAccessToken, self.newRefreshToken))
    }

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(self.manager.state, .authorized)
      callback(.success(1))
    }, completion: { (result: Result<MockResult, AuthError>) in
      XCTAssertEqual(try? result.get(), 1)
      withAccessExpect1.fulfill()
    })

    manager.withAccessToken(action: { (accessToken, callback ) in
      XCTAssertEqual(accessToken, self.newAccessToken)
      XCTAssertEqual(self.manager.state, .authorized)
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

    // our refresh call returns a new token
    // should only be called once
    delegate.addHandlerForRequireRefresh(description: "refresh token") { refreshToken in
      return .success((self.newAccessToken, self.newRefreshToken))
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

