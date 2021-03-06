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

  private(set) public var accessToken: AccessToken?
  private(set) public var refreshToken: RefreshToken?

  private var pendingRequests: [QueuedHandler] = []

  private(set) public var state: TokenManagerState {
    didSet {
      if oldValue != state {
        delegate?.tokenManagerDidUpdateState(state: state)
      }
    }
  }

  private var isAuthenticating: Bool {
    switch state {
    case .refreshing, .reauthorizing: return true
    case .unauthorized, .authorized: return false
    }
  }
      
  public init(accessToken: AccessToken?, refreshToken: RefreshToken?) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.state = accessToken == nil && refreshToken == nil ? .unauthorized : .authorized
  }

  public func isLoggedIn() -> Bool {
    switch state {
    case .authorized, .refreshing, .reauthorizing:
      return true
    case .unauthorized:
      return false
    }
  }

  /** Registers the tokens. This will resume all pending actions with the given accessToken  */
  public func authorize(accessToken: AccessToken, refreshToken: RefreshToken) {
    setTokens(accessToken: accessToken, refreshToken: refreshToken)
    state = .authorized
    handlePendingRequests(with: accessToken)
  }

  /** call this to abort the authorization. This will resolve all pending actions with the given error */
  public func abortAuthorization(with error: AuthError = .cancelled) {
    if state == .reauthorizing {
      // TODO: klopt dit?
      state = .unauthorized
      self.handlePendingRequests(with: error)
    }
  }

  public func logout() {
    setTokens(accessToken: nil, refreshToken: nil)
    state = .unauthorized
    handlePendingRequests(with: .noCredentials)
  }

  /** Sets a new refreshToken, this won't rerun queued actions */
  public func setRefreshToken(_ refreshToken: RefreshToken?) {
    setTokens(accessToken: accessToken, refreshToken: refreshToken)
  }

  public func setAccessToken(_ accessToken: AccessToken?) {
    setTokens(accessToken: accessToken, refreshToken: refreshToken)
  }

  private func setTokens(accessToken: AccessToken?, refreshToken: RefreshToken?) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    delegate?.tokenManagerDidUpdateTokens(accessToken: accessToken, refreshToken: refreshToken)
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
        self.addToQueue(action: action, completion: completion)
        self.refreshAccessToken()
      }

      guard !delegate.tokenManagerShouldTokenExpire(accessToken: accessToken) else {
        return onTokenExpired()
      }

      action(accessToken) { result in
        runOnMainAsync {
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
          action(token) { actionResult in
            runOnMainAsync {
              completion(actionResult)
            }
          }
        case let .failure(error):
          completion(.failure(error))
        }
      }

      self.pendingRequests.append(queuedHandler)
    }
  }
  
  private func refreshAccessToken() {
    guard !isAuthenticating else { return }
    state = .refreshing
    setTokens(accessToken: nil, refreshToken: self.refreshToken)

    guard let refreshToken = self.refreshToken else {
      return self.reauthorize()
    }
        
    delegate?.tokenManagerRequiresRefresh(refreshToken: refreshToken) { result in
      runOnMainAsync {
        switch result {
        case .success(let tokens):
          self.authorize(accessToken: tokens.0, refreshToken: tokens.1)
        case .failure(.unauthorized):
          self.reauthorize()
        case .failure(let error):
          self.state = .authorized
          self.handlePendingRequests(with: error)
        }
      }
    }
  }
  
  private func reauthorize() {
    state = .reauthorizing
    setTokens(accessToken: nil, refreshToken: nil)
    delegate?.tokenManagerRequiresAuthorization()
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
