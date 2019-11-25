//
//  MockStorage.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 25/11/2019.
//

import Foundation

class MockStorage: TokenManagerStorage {
  typealias AccessToken = String
  typealias RefreshToken = String

  var accessToken: AccessToken?
  var refreshToken: RefreshToken?

  init(accessToken: AccessToken?, refreshToken: RefreshToken?) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
  }
}
