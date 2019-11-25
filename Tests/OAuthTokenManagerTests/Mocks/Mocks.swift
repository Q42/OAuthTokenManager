//
//  Mocks.swift
//  OAuthTokenManager
//
//  Created by Tim van Steenis on 13/11/2019.
//

import Foundation
@testable import OAuthTokenManager

struct MockError: Error {}
typealias AccessToken = String
typealias RefreshToken = String
typealias MockResult = Int
typealias ActionResult = Result<MockResult, AuthError>
