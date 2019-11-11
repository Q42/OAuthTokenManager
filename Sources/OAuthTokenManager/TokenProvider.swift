//
//  TokenProvider.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public typealias ProviderResult<T> = CallbackResult<T, AuthError>
public typealias TokenCallback = (ProviderResult<AuthTokens>) -> Void

public protocol TokenProvider {
  associatedtype CredentialsType where CredentialsType == String
  
  func login(credentials: CredentialsType, callback: @escaping TokenCallback)
  func refreshAccessToken(refreshToken: RefreshToken, callback: @escaping TokenCallback)
}

struct EmailTokenProvider: TokenProvider {
  typealias CredentialsType = String
  
  func login(credentials: String, callback: @escaping TokenCallback) {
    
  }
  
  func refreshAccessToken(refreshToken: RefreshToken, callback: @escaping TokenCallback) {
    
  }
}
