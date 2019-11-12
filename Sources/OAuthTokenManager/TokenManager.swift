//
//  DefaultTokenManager.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

open class TokenManager<AccessToken, RefreshToken, Failure: Error> {
  typealias QueuedHandler = (AccessToken?, AuthError<Failure>?) -> Void
  
  public typealias ErrorType = AuthError<Failure>
    
  public typealias ActionResult<Success> = Swift.Result<Success, ErrorType>
  public typealias RefreshResult = Swift.Result<(AccessToken, RefreshToken), ErrorType>
  public typealias LoginResult = Swift.Result<(AccessToken, RefreshToken), ErrorType>
  
  public typealias LoginCompletionHandler = (LoginResult) -> Void
  public typealias RefreshCompletionHandler = (RefreshResult) -> Void
  public typealias ActionCallback<Success> = (ActionResult<Success>) -> Void
  public typealias Action<Success> = (AccessToken, @escaping ActionCallback<Success>) -> Void
  public typealias ActionCompletionHandler<Success> = (ActionResult<Success>) -> Void

  /** Will be called whenever the tokens update */
  public var didUpdateTokens: ((AccessToken?, RefreshToken?) -> Void)?
  
  /**
   This method will be called when the `withAccessToken` was called but there were no tokens or when the refreshToken is invalid.
   You should present a Login screen for the user and call the completion handler.
   All actions with `withAccessToken` will be queued until the completion handler is called with a result
   */
  public var didRequireLogin: ((@escaping LoginCompletionHandler) -> Void)?
  
  /** The accessToken needs to be refreshed */
  public var didRequireRefresh: ((RefreshToken, @escaping RefreshCompletionHandler) -> Void)?
    
  // TODO: Fix multithreading
  private var pendingRequests: [QueuedHandler] = []
  private var isAuthenticating: Bool = false
  
  private var refreshToken: RefreshToken?
  private var accessToken: AccessToken?
      
  public init(accessToken: AccessToken?, refreshToken: RefreshToken?) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
  }
  
  public func isLoggedIn() -> Bool {
    refreshToken != nil
  }
  
  public func set(accessToken: AccessToken, refreshToken: RefreshToken) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    didUpdateTokens?(accessToken, refreshToken)
    isAuthenticating = false
    handlePendingRequests(with: accessToken)
  }
  
  public func removeTokens() {    
    accessToken = nil
    refreshToken = nil
    didUpdateTokens?(nil, nil)
    handlePendingRequests(with: .noCredentials)
  }
    
  public func withAccessToken<Success>(
    action: @escaping Action<Success>,
    completion: @escaping ActionCompletionHandler<Success>
  ) {
    guard !isAuthenticating else {
      addToQueue(action: action, completion: completion)
      return
    }
    
    guard let accessToken = accessToken else {
      // we're not authorized anymore, add the request to the queue and start authenticating
      self.addToQueue(action: action, completion: completion)
      self.refreshAccessToken()
      return
    }
    
    action(accessToken) { [self] result in
      switch result {
      case .success(let value):
        completion(.success(value))
      case .failure(.unauthorized):
        // we're not authorized anymore, add the request to the queue and start authenticating
        self.accessToken = nil
        self.didUpdateTokens?(self.accessToken, self.refreshToken)
        self.addToQueue(action: action, completion: completion)
        self.refreshAccessToken()
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
    
  private func handlePendingRequests(with token: AccessToken) {
    let items = Array(pendingRequests)
    pendingRequests.removeAll()
    items.forEach { $0(token, nil) }
  }
    
  private func handlePendingRequests(with error: ErrorType) {
    let items = Array(pendingRequests)
    pendingRequests.removeAll()
    items.forEach { $0(nil, error) }
  }

  private func addToQueue<Success>(
    action: @escaping Action<Success>,
    completion: @escaping ActionCompletionHandler<Success>
  ) {
    let queuedHandler: QueuedHandler = { (token, error) in
      if let token = token {
        action(token) { result in
          switch result {
          case .success(let value):
            completion(.success(value))
          case .failure(let error):
            completion(.failure(error))
          }
        }
      } else if let error = error {
        completion(.failure(error))
      }
    }
    pendingRequests.append(queuedHandler)
  }
  
  private func refreshAccessToken() {
    guard !isAuthenticating else { return }
    isAuthenticating = true
    
    guard let refreshToken = refreshToken else {
      self.login()
      return;
    }
        
    didRequireRefresh?(refreshToken) { result in
      switch result {
      case .success(let tokens):
        self.set(accessToken: tokens.0, refreshToken: tokens.1)
      case .failure(.unauthorized):
        self.accessToken = nil
        self.refreshToken = nil
        self.didUpdateTokens?(nil, nil)
        self.login()
      case .failure(let error):
        self.handlePendingRequests(with: error)
        self.isAuthenticating = false
      }
    }
  }
  
  private func login() {
    self.didRequireLogin?() { [self] result in
      switch result {
      case .success(let tokens):
        self.set(accessToken: tokens.0, refreshToken: tokens.1)
      case .failure(.loginCancelled):
        self.isAuthenticating = false
        self.handlePendingRequests(with: .loginCancelled)
      case let .failure(error):
        self.isAuthenticating = false
        self.handlePendingRequests(with: error)
      }
    }
  }
}
