//
//  TokenManagerStorage.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 25/11/2019.
//

import Foundation

public protocol TokenManagerStorage: class {
  associatedtype AccessToken
  associatedtype RefreshToken

  var accessToken: AccessToken? { get set }
  var refreshToken: RefreshToken? { get set }
}
