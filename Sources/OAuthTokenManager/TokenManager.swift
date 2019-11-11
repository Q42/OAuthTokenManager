//
//  TokenManager.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

// TODO: rename callback methods

public enum TokenManagerError: Error {
  case noCredentials
  case loginCancelled
}

public typealias LoginCallback = (CallbackResult<Void, Error>) -> Void
public typealias RequestResultCallback<T> = (CallbackResult<T, AuthError>) -> Void
public typealias WithAccessTokenCallback<T> = (AccessToken, @escaping RequestResultCallback<T>) -> Void
public typealias WithAccessCompletion<T> = (CallbackResult<T, AuthError>) -> Void

public protocol TokenManager {
  var delegate: TokenManagerDelegate? { get set }
  
  func isLoggedIn() -> Bool
  func set(tokens: AuthTokens)
  func removeTokens()
  func withAccessToken<T>(callback: @escaping WithAccessTokenCallback<T>, completion: @escaping WithAccessCompletion<T>)
}

public enum LoginResult {
  case success(AuthTokens)
  case cancelled
  case error(Error)
}

public typealias LoginCompletionHandler = (LoginResult) -> Void
public typealias RefreshCompletionHandler = (CallbackResult<AuthTokens, AuthError>) -> Void

public protocol TokenManagerDelegate: class {
  /**
   This method will be called when the TokenManager needs new tokens.
   All calls with `withAccessToken` will be queued until `login` or `cancel` login will be called.
   */
  func tokenManagerRequiresLogin(service: TokenManager, completion: @escaping LoginCompletionHandler)
  
  func tokenManagerRequiresRefresh(service: TokenManager, with token: RefreshToken, completion: @escaping RefreshCompletionHandler)
}
