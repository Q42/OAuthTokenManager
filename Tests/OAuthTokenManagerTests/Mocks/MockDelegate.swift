//
//  MockDelegate.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 13/11/2019.
//

import XCTest
@testable import OAuthTokenManager

final class MockDelegate: TokenManagerDelegate {
  typealias AccessToken = String
  typealias RefreshToken = String

  typealias ExpectationGenerator = (String) -> XCTestExpectation
  
  typealias RequiresRefreshHandler = (RefreshToken) -> RefreshResult
  typealias RequiresAuthorizationHandler = () -> Void
  typealias ShouldExpireHandler = (AccessToken) -> Bool

  private var requiresRefreshHandlers: [(RequiresRefreshHandler, XCTestExpectation)] = []
  private var requiresLoginHandlers: [(RequiresAuthorizationHandler, XCTestExpectation)] = []
  private var shouldExpireHandlers: [(ShouldExpireHandler, XCTestExpectation)] = []

  private let expectation: ExpectationGenerator
  
  init(expectation: @escaping ExpectationGenerator) {
    self.expectation = expectation
  }
  
  var allExpectations: [XCTestExpectation] = []

  func addHandlerForRequireAuthorization(description: String, handler: @escaping RequiresAuthorizationHandler
  ) {
    let expec = expectation(description)
    requiresLoginHandlers.append((handler, expec))
    allExpectations.append(expec)
  }
  
  func addHandlerForRequireRefresh(description: String, handler: @escaping RequiresRefreshHandler) {
    let expec = expectation(description)
    requiresRefreshHandlers.append((handler, expec))
    allExpectations.append(expec)
  }

  func addHandlerForShouldExpire(description: String, handler: @escaping ShouldExpireHandler) {
    let expec = expectation(description)
    shouldExpireHandlers.append((handler, expec))
    allExpectations.append(expec)
  }

  func tokenManagerRequiresAuthorization() {
    guard let (handler, expec) = requiresLoginHandlers.first else {
      return XCTFail("No handler for tokenManagerRequiresLogin. Been called too many times")
    }
    _ = requiresLoginHandlers.removeFirst()
    handler()
    expec.fulfill()
  }
  
  func tokenManagerRequiresRefresh(refreshToken: RefreshToken, completion: @escaping RefreshCompletionHandler) {
    guard let (handler, expec) = requiresRefreshHandlers.first else {
      return XCTFail("No handler for tokenManagerRequiresRefresh. Been called too many times")
    }
    _ = requiresRefreshHandlers.removeFirst()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      completion(handler(refreshToken))
      expec.fulfill()
    }
  }

  func tokenManagerShouldTokenExpire(accessToken: AccessToken) -> Bool {
    guard let (handler, expec) = shouldExpireHandlers.first else {
      XCTFail("No handler for shouldExpireHandler. Been called too many times")
      return false
    }
    _ = shouldExpireHandlers.removeFirst()
    expec.fulfill()
    return handler(accessToken)
  }

  func tokenManagerDidUpdateState(state: TokenManagerState) {
  }

  func tokenManagerDidUpdateTokens(accessToken: AccessToken?, refreshToken: RefreshToken?) { }
}
