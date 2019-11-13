//
//  DefaultTokenManager.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

open class TokenManager<Delegate: TokenManagerDelegate> {
  public typealias AccessToken = Delegate.AccessToken
  public typealias RefreshToken = Delegate.RefreshToken
  public typealias Failure = Delegate.Failure
  
  typealias QueuedHandler = (AccessToken?, AuthError<Failure>?) -> Void
  
  public typealias ErrorType = AuthError<Failure>
  public typealias ActionResult<Success> = Swift.Result<Success, ErrorType>
  public typealias ActionCallback<Success> = (ActionResult<Success>) -> Void
  public typealias Action<Success> = (AccessToken, @escaping ActionCallback<Success>) -> Void
  public typealias ActionCompletionHandler<Success> = (ActionResult<Success>) -> Void
  
  public weak var delegate: Delegate?

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
    delegate?.tokenManagerDidUpdateTokens(manager: self, accessToken: self.accessToken, refreshToken: self.refreshToken)
    isAuthenticating = false
    handlePendingRequests(with: accessToken)
  }
  
  public func removeTokens() {    
    accessToken = nil
    refreshToken = nil
    delegate?.tokenManagerDidUpdateTokens(manager: self, accessToken: self.accessToken, refreshToken: self.refreshToken)
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
        self.delegate?.tokenManagerDidUpdateTokens(manager: self, accessToken: self.accessToken, refreshToken: self.refreshToken)
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
        
    delegate?.tokenManagerRequiresRefresh(manager: self, refreshToken: refreshToken) { result in
      switch result {
      case .success(let tokens):
        self.set(accessToken: tokens.0, refreshToken: tokens.1)
      case .failure(.unauthorized):
        self.accessToken = nil
        self.refreshToken = nil
        self.delegate?.tokenManagerDidUpdateTokens(manager: self, accessToken: self.accessToken, refreshToken: self.refreshToken)
        self.login()
      case .failure(let error):
        self.handlePendingRequests(with: error)
        self.isAuthenticating = false
      }
    }
  }
  
  private func login() {
    delegate?.tokenManagerRequiresLogin(manager: self) { [self] result in
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
