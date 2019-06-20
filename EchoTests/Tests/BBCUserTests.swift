//
// Created by Adam Price on 16/02/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

@testable import Echo

class BBCUserTests: XCTestCase {

    let HashedID = "1234"
    let TokenRefreshTimestamp = Date()

    var user: BBCUser!
    let signedOut: BBCUser = BBCUser(signedIn: false, hashedID: nil, tokenRefreshTimestamp: nil)
    let signedIn: BBCUser = BBCUser(signedIn: true, hashedID: nil, tokenRefreshTimestamp: nil)
    let signedInWithHid: BBCUser = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: nil)
    let signedInWithHidDiff: BBCUser = BBCUser(signedIn: true, hashedID: "abc", tokenRefreshTimestamp: nil)

    override func setUp() {
        super.setUp()

        user = BBCUser(signedIn: false, hashedID: HashedID, tokenRefreshTimestamp: TokenRefreshTimestamp)
    }

    func testUserReturnsSignedInStatus() {
        assertThat(user.signedIn, equalTo(false))
    }

    func testUserHashedIDNilWhenSignedOut() {
        assertThat(user.hashedID, nilValue())
    }

    func testUserReturnsHashedIDWhenSignedIn() {
        user = BBCUser(signedIn: true, hashedID: HashedID, tokenRefreshTimestamp: TokenRefreshTimestamp)
        assertThat(user.hashedID, presentAnd(equalTo(HashedID)))
    }

    func testUserReturnsTokenRefreshTimestamp() {
        assertThat(user.tokenRefreshTimestamp, presentAnd(equalTo(TokenRefreshTimestamp)))
    }

    func testGetTokenStatus() {
        user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
        assertThat(user.tokenState(), presentAnd(equalTo(.valid)))

        user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date(timeIntervalSince1970: 1))
        assertThat(user.tokenState(), presentAnd(equalTo(.expired)))

        user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: nil)
        assertThat(user.tokenState(), presentAnd(equalTo(.validNoTimestamp)))

        user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date() + 86400)
        assertThat(user.tokenState(), presentAnd(equalTo(.validNoTimestamp)))
    }

    func testGetTimeUntilTokenExpiry() {
        user = BBCUser(signedIn: true, hashedID: HashedID, tokenRefreshTimestamp: nil)
        assertThat(user.getTimeUntilTokenExpiry(), presentAnd(equalTo(0)))

        // have to round these values because they are milliseconds out otherwise
        user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
        assertThat(round(user.getTimeUntilTokenExpiry()), presentAnd(equalTo(86400)))

        user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date() - 86340)
        assertThat(round(user.getTimeUntilTokenExpiry()), presentAnd(equalTo(60)))
    }
    
    func testReturnNoneUserStateTransition() {
        assertThat(signedOut.getUserStateTransition(user: nil), presentAnd(equalTo(UserStateTransition.none)))
    }
    
    func testReturnNoneUserStateTransitionWhenSignedIn() {
        assertThat(signedIn.getUserStateTransition(user: signedIn), presentAnd(equalTo(UserStateTransition.none)))
    }
    
    func testReturnNoneUserStateTransitionWhenSignedInWithHid() {
        assertThat(signedInWithHid.getUserStateTransition(user: signedInWithHid), presentAnd(equalTo(UserStateTransition.none)))
    }
    
    func testReturnSignInUserStateTransition() {
        assertThat(signedOut.getUserStateTransition(user: signedIn), presentAnd(equalTo(UserStateTransition.signIn)))
    }
    
    func testReturnSignInUserStateTransitionWithHid() {
        assertThat(signedOut.getUserStateTransition(user: signedInWithHid), presentAnd(equalTo(UserStateTransition.signIn)))
    }
    
    func testReturnSignInUserStateTransitionWithChangrInHid() {
        assertThat(signedInWithHid.getUserStateTransition(user: signedInWithHidDiff), presentAnd(equalTo(UserStateTransition.signIn)))
    }
    
    func testReturnSignOutUserStateTransition() {
        assertThat(signedIn.getUserStateTransition(user: signedOut), presentAnd(equalTo(UserStateTransition.signOut)))
    }
    
    func testReturnSignOutUserStateTransitionWhenNull() {
        assertThat(signedIn.getUserStateTransition(user: nil), presentAnd(equalTo(UserStateTransition.signOut)))
    }
    
    func testReturnOutUserStateTransitionWithHid() {
        assertThat(signedInWithHid.getUserStateTransition(user: signedOut), presentAnd(equalTo(UserStateTransition.signOut)))
    }
    
    func testReturnEPUserStateTransition() {
        assertThat(signedIn.getUserStateTransition(user: signedInWithHid), presentAnd(equalTo(UserStateTransition.enablePersonalisation)))
    }
    
    func testReturnDPUserStateTransition() {
        assertThat(signedInWithHid.getUserStateTransition(user: signedIn), presentAnd(equalTo(UserStateTransition.disablePersonalisation)))
    }
}
