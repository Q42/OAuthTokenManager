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
  typealias Failure = MockError
  
  typealias ExpectationGenerator = (String) -> XCTestExpectation
  
  typealias UpdateTokenAssertion = (String?, String?) -> Void
  typealias RequiresRefreshAssertion = (RefreshToken) -> RefreshResult
  typealias RequiresLoginAssertion = () -> LoginResult
  
  private var updateTokenHandlers: [(UpdateTokenAssertion, XCTestExpectation)] = []
  private var requiresRefreshHandlers: [(RequiresRefreshAssertion, XCTestExpectation)] = []
  private var requiresLoginHandlers: [(RequiresLoginAssertion, XCTestExpectation)] = []
  
  private let expectation: ExpectationGenerator
  
  init(expectation: @escaping ExpectationGenerator) {
    self.expectation = expectation
  }
  
  var allExpectations: [XCTestExpectation] = []
  
  func addHandlerForUpdateToken(description: String, handler: @escaping UpdateTokenAssertion) {
    let expec = expectation(description)
    updateTokenHandlers.append((handler, expec))
    allExpectations.append(expec)
  }
  
  func addHandlerForRequireLogin(description: String, handler: @escaping RequiresLoginAssertion
  ) {
    let expec = expectation(description)
    requiresLoginHandlers.append((handler, expec))
    allExpectations.append(expec)
  }
  
  func addHandlerForRequireRefresh(description: String, handler: @escaping RequiresRefreshAssertion) {
    let expec = expectation(description)
    requiresRefreshHandlers.append((handler, expec))
    allExpectations.append(expec)
  }
  
  func tokenManagerDidUpdateTokens(manager: TokenManager<MockDelegate>, accessToken: AccessToken?, refreshToken: RefreshToken?) {
    guard let (handler, expec) = updateTokenHandlers.dropFirst().first else {
      return XCTFail("No handler for tokenManagerDidUpdateTokens. Been called too many times")
    }
    handler(accessToken, refreshToken)
    expec.fulfill()
  }
  
  func tokenManagerRequiresLogin(manager: TokenManager<MockDelegate>, completion: @escaping LoginCompletionHandler) {
    guard let (handler, expec) = requiresLoginHandlers.dropFirst().first else {
      return XCTFail("No handler for tokenManagerRequiresLogin. Been called too many times")
    }
    completion(handler())
    expec.fulfill()
  }
  
  func tokenManagerRequiresRefresh(manager: TokenManager<MockDelegate>, refreshToken: String, completion: @escaping RefreshCompletionHandler) {
    guard let (handler, expec) = requiresRefreshHandlers.dropFirst().first else {
      return XCTFail("No handler for tokenManagerRequiresRefresh. Been called too many times")
    }
    completion(handler(refreshToken))
    expec.fulfill()
  }
}
