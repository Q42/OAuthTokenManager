//
//  AuthError.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public enum AuthError: Error {
  case notAuthorized
  case other(Error)
}
