//
//  UserPromiseMock.swift
//  EchoTests
//
//  Created by Andrew Ryan on 28/08/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import Foundation
import Echo

class UserPromiseMock: UserPromise {
    func setBBCUser(_ user: BBCUser?) -> UserPromiseHelperResult {
        return UserPromiseHelperResult()
    }

    func getBBCUser() -> BBCUser {
        return BBCUser()
    }

    func getDeviceID() -> String? {
        return "testDevice"
    }

    func clearWebviewCookies() {

    }

    func setPostponedUserStateTransition(userStateTransition: UserStateTransition) {

    }

    func clearPostponedUserStateTransition() {

    }

    
}
