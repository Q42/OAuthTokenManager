//
//  AuthStorage.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public protocol AuthStorage: class {
  var accessTokenValue: String? { get set }
  var accessTokenExpirationDate: Date? { get set }
  var refreshTokenValue: String? { get set }
}

extension AuthStorage {
  var accessToken: AccessToken? {
    get {
      if let accessTokenValue = accessTokenValue, let accessTokenExpirationDate = accessTokenExpirationDate {
        return AccessToken(token: accessTokenValue, expirationDate: accessTokenExpirationDate)
      }
      return nil
    }
    set {
      accessTokenValue = newValue?.token
      accessTokenExpirationDate = newValue?.expirationDate
    }
  }

  var refreshToken: RefreshToken? {
    get {
      return refreshTokenValue.map(RefreshToken.init)
    }
    set {
      refreshTokenValue = newValue?.token
    }
  }

  var tokens: AuthTokens? {
    get {
      if let accessToken = accessToken, let refreshToken = refreshToken {
        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
      }
      return nil
    }
    set {
      refreshToken = newValue?.refreshToken
      accessToken = newValue?.accessToken
    }
  }
}
