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

  typealias QueuedHandler = (Result<AccessToken, AuthError>) -> Void

  public typealias ActionResult<Success> = Swift.Result<Success, AuthError>
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
  
  public func setRefreshedTokens(accessToken: AccessToken, refreshToken: RefreshToken) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    delegate?.tokenManagerDidUpdateTokens(accessToken: self.accessToken, refreshToken: self.refreshToken)
    isAuthenticating = false
    handlePendingRequests(with: accessToken)
  }

  public func removeAccessToken() {
    accessToken = nil
    delegate?.tokenManagerDidUpdateTokens(accessToken: self.accessToken, refreshToken: self.refreshToken)
  }

  public func removeRefreshToken() {
    refreshToken = nil
    delegate?.tokenManagerDidUpdateTokens(accessToken: self.accessToken, refreshToken: self.refreshToken)
  }
  
  public func removeTokens() {
    self.removeAccessToken()
    refreshToken = nil
    delegate?.tokenManagerDidUpdateTokens(accessToken: self.accessToken, refreshToken: self.refreshToken)
    handlePendingRequests(with: .noCredentials)
  }
    
  public func withAccessToken<Success>(
    action: @escaping Action<Success>,
    completion: @escaping ActionCompletionHandler<Success>
  ) {
    guard let delegate = delegate else {
      return print("OAuthTokenManager: No delegate has been set")
    }

    runOnMainAsync {

      guard !self.isAuthenticating else {
        self.addToQueue(action: action, completion: completion)
        return
      }

      guard let accessToken = self.accessToken else {
        // we're not authorized anymore, add the request to the queue and start authenticating
        self.addToQueue(action: action, completion: completion)
        self.refreshAccessToken()
        return
      }

      func onTokenExpired() {
        // we're not authorized anymore, add the request to the queue and start authenticating
        self.accessToken = nil
        self.delegate?.tokenManagerDidUpdateTokens(accessToken: self.accessToken, refreshToken: self.refreshToken)
        self.addToQueue(action: action, completion: completion)
        self.refreshAccessToken()
      }

      guard !delegate.tokenManagerShouldTokenExpire(accessToken: accessToken) else {
        return onTokenExpired()
      }

      action(accessToken) { result in
        switch result {
        case .success(let value):
          completion(.success(value))
        case .failure(.unauthorized):
          onTokenExpired()
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }
    
  private func handlePendingRequests(with token: AccessToken) {
    runOnMainAsync {
      let items = Array(self.pendingRequests)
      self.pendingRequests.removeAll()
      items.forEach { $0(.success(token)) }
    }
  }
    
  private func handlePendingRequests(with error: AuthError) {
    runOnMainAsync {
      let items = Array(self.pendingRequests)
      self.pendingRequests.removeAll()
      items.forEach { $0(.failure(error)) }
    }
  }

  private func addToQueue<Success>(
    action: @escaping Action<Success>,
    completion: @escaping ActionCompletionHandler<Success>
  ) {
    runOnMainAsync {
      let queuedHandler: QueuedHandler = { result in
        switch result {
        case let .success(token):
          action(token) { completion($0) }
        case let .failure(error):
          completion(.failure(error))
        }
      }

      self.pendingRequests.append(queuedHandler)
    }
  }
  
  private func refreshAccessToken() {
    guard !isAuthenticating else { return }
    isAuthenticating = true
    
    guard let refreshToken = refreshToken else {
      return self.login()
    }
        
    delegate?.tokenManagerRequiresRefresh(refreshToken: refreshToken) { result in
      runOnMainAsync {
        switch result {
        case .success(let tokens):
          self.setRefreshedTokens(accessToken: tokens.0, refreshToken: tokens.1)
        case .failure(.unauthorized):
          self.accessToken = nil
          self.refreshToken = nil
          self.delegate?.tokenManagerDidUpdateTokens(accessToken: self.accessToken, refreshToken: self.refreshToken)
          self.login()
        case .failure(let error):
          self.handlePendingRequests(with: error)
          self.isAuthenticating = false
        }
      }
    }
  }
  
  private func login() {
    delegate?.tokenManagerRequiresLogin { [self] result in
      runOnMainAsync {
        switch result {
        case .success(let tokens):
          self.setRefreshedTokens(accessToken: tokens.0, refreshToken: tokens.1)
        case let .failure(error):
          self.isAuthenticating = false
          self.handlePendingRequests(with: error)
        }
      }
    }
  }
}

private func runOnMainAsync(block: @escaping () -> Void) {
  if Thread.isMainThread {
    block()
  } else {
    DispatchQueue.main.async {
      block()
    }
  }
}
