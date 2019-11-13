//
//  TokenManagerDelegate.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 13/11/2019.
//

import Foundation

public protocol TokenManagerDelegate: class {
  associatedtype AccessToken
  associatedtype RefreshToken
  associatedtype Failure: Error
      
  typealias RefreshResult = Swift.Result<(AccessToken, RefreshToken), AuthError<Failure>>
  typealias LoginResult = Swift.Result<(AccessToken, RefreshToken), AuthError<Failure>>
  typealias RefreshCompletionHandler = (RefreshResult) -> Void
  typealias LoginCompletionHandler = (LoginResult) -> Void
  
  /** Will be called whenever the tokens update */
  func tokenManagerDidUpdateTokens(manager: TokenManager<Self>, accessToken: AccessToken?, refreshToken: RefreshToken?)
  
  /**
   This method will be called when the `withAccessToken` was called but there were no tokens or when the refreshToken is invalid.
   You should present a Login screen for the user and call the completion handler.
   All actions with `withAccessToken` will be queued until the completion handler is called with a result
   */
  func tokenManagerRequiresLogin(manager: TokenManager<Self>, completion: @escaping LoginCompletionHandler)
  
  /** The accessToken needs to be refreshed */
  func tokenManagerRequiresRefresh(manager: TokenManager<Self>, refreshToken: RefreshToken, completion: @escaping RefreshCompletionHandler)
}
