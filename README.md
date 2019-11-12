# OAuthTokenManager

## Usage

```swift

import OAuthTokenManager

// First, define your AccessToken and RefeshToken structs

struct AccessToken {
  let token: String  
}

struct RefreshToken {
  let token: String  
}

// Subclass the TokenManager

class MyTokenManager: TokenManager<AccessToken, RefreshToken {}

let tokenManager = MyTokenManager(
  accessToken: nil,
  refreshToken: nil,
)

// register the following handlers

manager.didUpdateTokens = { accessToken, refreshToken in
  // store the tokens in keychain
}

manager.didRequireRefresh = { (refreshToken, completion) in
  // call your API to refresh the accessToken, e.g
  let accessToken = AccessToken(token: "foo")
  
    
  completion(.success(accessToken, refreshToken))
  
  // or if you have a unauthorized error:
  
  completion(.error(.notAuthorized))
  
  // or if you have anothoer error
  
  completion(.error(.other(error))  
}

manager.didRequireLogin = { completion in
  
  // show a login screen to the user
  
  let accessToken = AccessToken(token: "foo")
  let refreshToken = RefreshToken(token: "bar")
  
  // when successful
  completion(.success(accessToken, refreshToken))

  // when cancelled
  
  completion(.cancelled)
  
  // when an error occured
  completion(.error(NSError()))
}

// now you can use the manager to perform actions which require a valid access token

struct MyResult {}

manager.withAccessToken(action: { (token, completion) in
  // perform api call
  completion(.success(MyResult()))

  // or when you receive a unauthorized error
  completion(.error(.notAuthorized))

  // or when you receive another error
  completion(.error(.other(NSError())))

}) { (result: ActionResult<MyResult>) in
  // here you can prosses

  switch result {
  case let .success(value):
   break
  case let .error(error):
   break
  }
}

```

