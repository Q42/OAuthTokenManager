//
//  AuthTokens.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public struct AuthTokens {
  public let accessToken: AccessToken
  public let refreshToken: RefreshToken
  
  public init(accessToken: AccessToken, refreshToken: RefreshToken) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
  }
}
