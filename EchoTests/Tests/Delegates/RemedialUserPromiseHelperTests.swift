//
//  RemedialTests.swift
//  EchoTests
//
//  Created by Mark Turner on 10/01/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

class RemedialUserPromiseHelperTests: XCTestCase {

    // these tests won't pass when run with the others, so trying them in a separate file

    let LoggedInPersonalisationOn = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
    let LoggedInExpiredToken = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date(timeIntervalSince1970: 1))
    let LoggedOut = BBCUser()

    var userDefaults: UserDefaults!
    var device: EchoDevice!
    var webviewCookieManager: MockWebviewCookieManager!

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: "testDefaults")
        userDefaults = UserDefaults(suiteName: "testDefaults")
        device = EchoDevice(userDefaults: userDefaults)
        webviewCookieManager = MockWebviewCookieManager().withEnabledSuperclassSpy()
    }

    override func tearDown() {
        device.userDefaults.removePersistentDomain(forName: "testDefaults")
        device.userDefaults.synchronize()
        super.tearDown()
    }

    func testPersistentIdentifiersShouldBeChangedIfSignInStateChanges() {
        device.userDefaults.removeObject(forKey: UserDefaultsKeys.echoHashedID.rawValue)
        device.userDefaults.set(true, forKey: UserDefaultsKeys.echoSignedIn.rawValue)
        device.userDefaults.set("defaultValue", forKey: UserDefaultsKeys.echoDeviceID.rawValue)
        device.userDefaults.synchronize()

        _ = UserPromiseHelper(device: device,
                              webviewCookiesEnabled: false).setBBCUser(LoggedInPersonalisationOn)

        assertThat(device.userDefaults.string(forKey: UserDefaultsKeys.echoDeviceID.rawValue),
                   presentAnd(not(equalTo("defaultValue"))))
        assertThat(device.userDefaults.string(forKey: UserDefaultsKeys.echoHashedID.rawValue),
                   presentAnd(equalTo("1234")))
    }

    func testShouldGenerateAValidUUIDAsADeviceID() {
        let helper = UserPromiseHelper(device: device,
                                       webviewCookiesEnabled: false)
        _ = helper.setBBCUser(LoggedOut)
        let range = helper.getDeviceID()!.range(of: "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
                                                options: .regularExpression)
        assertThat(range?.isEmpty, presentAnd(equalTo(false)))
    }
}
