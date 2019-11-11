//
//  DefaultTokenManager.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

private typealias QueuedHandler = (AccessToken?, Error?) -> Void

public class DefaultTokenManager: TokenManager {

  public weak var delegate: TokenManagerDelegate?
      
  private let storage: AuthStorage
  // TODO: Fix multithreading
  private var pendingRequests: [QueuedHandler] = []
  private var isAuthenticating: Bool = false
    
  public init(storage: AuthStorage) {
    self.storage = storage    
  }
  
  public func isLoggedIn() -> Bool {
    storage.refreshToken != nil
  }
  
  public func set(tokens: AuthTokens) {
    storage.tokens = tokens
    isAuthenticating = false
    handlePendingRequests(with: tokens.accessToken)
  }
  
  public func removeTokens() {
    storage.tokens = nil
    handlePendingRequests(with: TokenManagerError.noCredentials)
  }
    
  public func withAccessToken<T>(
    callback: @escaping WithAccessTokenCallback<T>,
    completion: @escaping WithAccessCompletion<T>
  ) {
    guard !isAuthenticating else {
      addToQueue(callback: callback, completion: completion)
      return
    }
    
    guard let accessToken = storage.accessToken else {
      // we're not authorized anymore, add the request to the queue and start authenticating
      self.addToQueue(callback: callback, completion: completion)
      self.refreshAccessToken()
      return
    }
    
    callback(accessToken) { [self] result in
      switch result {
      case .success(let value):
        completion(.success(value))
      case .error(.notAuthorized):
        // we're not authorized anymore, add the request to the queue and start authenticating
        self.addToQueue(callback: callback, completion: completion)
        self.refreshAccessToken()
      case .error(let error):
        completion(.error(error))
      }
    }
  }
    
  private func handlePendingRequests(with token: AccessToken) {
    let items = Array(pendingRequests)
    pendingRequests.removeAll()
    items.forEach { $0(token, nil) }
  }
    
  private func handlePendingRequests(with error: Error) {
    let items = Array(pendingRequests)
    pendingRequests.removeAll()
    items.forEach { $0(nil, error) }
  }

  private func addToQueue<T>(
    callback: @escaping WithAccessTokenCallback<T>,
    completion: @escaping WithAccessCompletion<T>
  ) {
    let queuedHandler: QueuedHandler = { (token, error) in
      if let token = token {
        callback(token) { result in
          switch result {
          case .success(let value):
            completion(.success(value))
          case .error(let error):
            completion(.error(error))
          }
        }
      } else if let error = error {
        completion(.error(.other(error)))
      }
    }
    pendingRequests.append(queuedHandler)
  }
  
  private func refreshAccessToken() {
    guard !isAuthenticating else { return }
    isAuthenticating = true
    
    guard let refreshToken = storage.refreshToken else {
      self.login()
      return;
    }
    
    delegate?.tokenManagerRequiresRefresh(service: self, with: refreshToken) { result in
      switch result {
      case .success(let tokens):
        self.set(tokens: tokens)
      case .error(.notAuthorized):
        // we need to request a login
        self.login()
      case .error(let error):
        self.isAuthenticating = false
        self.handlePendingRequests(with: error)
      }
    }
  }
  
  private func login() {
    delegate?.tokenManagerRequiresLogin(service: self) { [self] result in
      switch result {
      case .success(let tokens):
        self.storage.tokens = tokens
        self.handlePendingRequests(with: tokens.accessToken)
      case .cancelled:
        self.isAuthenticating = false
        self.handlePendingRequests(with: TokenManagerError.loginCancelled)
      case .error(let error):
        // TODO: willen we hier de error mee sturen?
        self.isAuthenticating = false
        self.handlePendingRequests(with: error)
      }
    }
  }
}
