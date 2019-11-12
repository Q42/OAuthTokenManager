import XCTest
@testable import OAuthTokenManager

final class OAuthTokenManagerTests: XCTestCase {
  func testExample() {
    let manager = TokenManager<MyAccessToken, MyRefreshToken>(accessToken: nil, refreshToken: nil)
    manager.didUpdateTokens = { accessToken, refreshToken in
      
    }
    
    manager.didRequireLogin = { completion in
      
    }
    
    manager.didRequireRefresh = { (refreshToken, completion) in
      
    }
    
    struct MyResult {
      
    }
    
    manager.withAccessToken(action: { (token, completion) in
      // perform api call
      completion(.success(MyResult()))
      
      // or when you receive a unauthorized error
      
      completion(.error(.notAuthorized))
      
      // or when you receive another error
      
      completion(.error(.other(NSError())))      
      
    }) { (result: ActionResult<MyResult>) in
      
      switch result {
      case let .success(value):
        break
      case let .error(error):
        break
      }
      
    }
  }
  
  static var allTests = [
    ("testExample", testExample),
  ]
}

struct MyAccessToken {
  let token: String
  let expires_in: Int?
}

struct MyRefreshToken {
  let value: String
}
