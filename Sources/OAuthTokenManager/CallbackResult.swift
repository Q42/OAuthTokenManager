//
//  CallbackResult.swift
//  OAuth2TokenManager
//
//  Created by Tim van Steenis on 10/11/2019.
//

import Foundation

public enum Result<T, E> {
  case success(T)
  case error(E)
}
