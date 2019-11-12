//
//  AuthError.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public enum AuthError<Failure: Error>: Error {
  case unauthorized
  case noCredentials
  case loginCancelled
  case other(Failure)
}
