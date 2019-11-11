//
//  RefreshToken.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public struct RefreshToken {
  public let token: String
  
  public init(token: String) {
    self.token = token
  }
}
