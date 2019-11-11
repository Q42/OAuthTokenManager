//
//  AccessToken.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public struct AccessToken {
  public let token: String
  public let expirationDate: Date
  
  public init(token: String, expirationDate: Date) {
    self.token = token
    self.expirationDate = expirationDate
  }
}

extension AccessToken {
  func isExpiredAfter(seconds: TimeInterval) -> Bool {
    return Date() + seconds >= expirationDate
  }
}
