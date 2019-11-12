//
//  CallbackResult.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public enum ActionError<E: Error>: Error {
  case error(E)
  case other(Error)
}

public enum Result<T, E> {
  case success(T)
  case error(E)
}

public enum TokenManagerError: Error {
  case noCredentials
  case loginCancelled
}

public enum LoginResult<AccessToken, RefreshToken> {
  case success(AccessToken, RefreshToken)
  case cancelled
  case error(Error)
}

public typealias ActionResult<T, E: Error> = Result<T, ActionError<E>>

public typealias RefreshResult<AccessToken, RefreshToken> = Result<(AccessToken, RefreshToken), AuthError>
