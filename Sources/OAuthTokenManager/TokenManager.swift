//
//  TokenManager.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public enum TokenManagerError: Error {
  case noCredentials
  case loginCancelled
}

public typealias LoginCallback = (Result<Void, Error>) -> Void
public typealias RequestCompletion<T> = (Result<T, AuthError>) -> Void
public typealias WithAccessTokenAction<T> = (AccessToken, @escaping RequestCompletion<T>) -> Void
public typealias WithAccessTokenCompletion<T> = (Result<T, AuthError>) -> Void

public protocol TokenManager {
  var delegate: TokenManagerDelegate? { get set }
  
  func isLoggedIn() -> Bool
  func set(tokens: AuthTokens)
  func removeTokens()
  func withAccessToken<T>(action: @escaping WithAccessTokenAction<T>,
                          completion: @escaping WithAccessTokenCompletion<T>)
}

public enum LoginResult {
  case success(AuthTokens)
  case cancelled
  case error(Error)
}

public typealias LoginCompletionHandler = (LoginResult) -> Void
public typealias RefreshCompletionHandler = (Result<AuthTokens, AuthError>) -> Void

public protocol TokenManagerDelegate: class {
  /**
   This method will be called when the TokenManager needs new tokens.
   All calls with `withAccessToken` will be queued until `login` or `cancel` login will be called.
   */
  func tokenManagerRequiresLogin(service: DefaultTokenManager,
                                 completion: @escaping LoginCompletionHandler)
  
  func tokenManagerRequiresRefresh(service: DefaultTokenManager,
                                   with token: RefreshToken,
                                   completion: @escaping RefreshCompletionHandler)
}
