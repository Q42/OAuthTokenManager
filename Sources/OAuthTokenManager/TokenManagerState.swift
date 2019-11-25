//
//  TokenManagerState.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 25/11/2019.
//

import Foundation

public enum TokenManagerState {
  /** credentials have been set */
  case authorized

  /** no credentials have been set */
  case unauthorized

  /** access token is being refreshed */
  case refreshing

  /** the manager is currently reauthorizing and is waiting for `authorize` or `abortAuthorization` to be called */
  case reauthorizing
}
