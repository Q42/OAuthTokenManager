//
//  AuthStorage.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public protocol AuthStorage: class {
  associatedtype AccessTokenType
  associatedtype RefreshTokenType
  
  var accessToken: AccessTokenType? { get set }
  var refreshToken: RefreshTokenType? { get set }
}
