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
      
  typealias RefreshResult = Swift.Result<(AccessToken, RefreshToken), AuthError>
  typealias LoginResult = Swift.Result<(AccessToken, RefreshToken), AuthError>
  typealias RefreshCompletionHandler = (RefreshResult) -> Void
  typealias LoginCompletionHandler = (LoginResult) -> Void
  
  /** Will be called whenever the tokens update */
  func tokenManagerDidUpdateTokens(accessToken: AccessToken?, refreshToken: RefreshToken?)
  
  /**
   This method will be called when the `withAccessToken` was called but there were no tokens or when the refreshToken is invalid.
   You should present a Login screen for the user and call the completion handler.
   All actions with `withAccessToken` will be queued until the completion handler is called with a result
   */
  func tokenManagerRequiresLogin(completion: @escaping LoginCompletionHandler)
  
  /** The accessToken needs to be refreshed */
  func tokenManagerRequiresRefresh(refreshToken: RefreshToken, completion: @escaping RefreshCompletionHandler)

  /** Return true if the token should be considered as expired **/
  func tokenManagerShouldTokenExpire(accessToken: AccessToken) -> Bool
}
