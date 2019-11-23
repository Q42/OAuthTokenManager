//
//  MockDelegate.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 13/11/2019.
//

import XCTest

final class MockDelegate: TokenManagerDelegate {
  typealias AccessToken = String
  typealias RefreshToken = String

  typealias ExpectationGenerator = (String) -> XCTestExpectation
  
  typealias UpdateTokenHandler = (String?, String?) -> Void
  typealias RequiresRefreshHandler = (RefreshToken) -> RefreshResult
  typealias RequiresLoginHandler = () -> LoginResult
  typealias ShouldExpireHandler = (AccessToken) -> Bool
  
  private var updateTokenHandlers: [(UpdateTokenHandler, XCTestExpectation)] = []
  private var requiresRefreshHandlers: [(RequiresRefreshHandler, XCTestExpectation)] = []
  private var requiresLoginHandlers: [(RequiresLoginHandler, XCTestExpectation)] = []
  private var shouldExpireHandlers: [(ShouldExpireHandler, XCTestExpectation)] = []
  
  private let expectation: ExpectationGenerator
  
  init(expectation: @escaping ExpectationGenerator) {
    self.expectation = expectation
  }
  
  var allExpectations: [XCTestExpectation] = []
  
  func addHandlerForUpdateToken(description: String, handler: @escaping UpdateTokenHandler) {
    let expec = expectation(description)
    updateTokenHandlers.append((handler, expec))
    allExpectations.append(expec)
  }
  
  func addHandlerForRequireLogin(description: String, handler: @escaping RequiresLoginHandler
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
  
  func tokenManagerDidUpdateTokens(accessToken: AccessToken?, refreshToken: RefreshToken?) {
    guard let (handler, expec) = updateTokenHandlers.first else {
      return XCTFail("No handler for tokenManagerDidUpdateTokens. Been called too many times")
    }
    _ = updateTokenHandlers.removeFirst()
    handler(accessToken, refreshToken)
    expec.fulfill()
  }
  
  func tokenManagerRequiresLogin(completion: @escaping LoginCompletionHandler) {
    guard let (handler, expec) = requiresLoginHandlers.first else {
      return XCTFail("No handler for tokenManagerRequiresLogin. Been called too many times")
    }
    _ = requiresLoginHandlers.removeFirst()
    completion(handler())
    expec.fulfill()
  }
  
  func tokenManagerRequiresRefresh(refreshToken: RefreshToken, completion: @escaping RefreshCompletionHandler) {
    guard let (handler, expec) = requiresRefreshHandlers.first else {
      return XCTFail("No handler for tokenManagerRequiresRefresh. Been called too many times")
    }
    _ = requiresRefreshHandlers.removeFirst()
    completion(handler(refreshToken))
    expec.fulfill()
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
}
