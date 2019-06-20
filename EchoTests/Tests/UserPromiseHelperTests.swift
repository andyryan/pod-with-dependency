//
// Created by Adam Price on 16/02/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

class UserPromiseHelperTests: XCTestCase {

    let LoggedInPersonalisationOn = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
    let LoggedInExpiredToken = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date(timeIntervalSince1970: 1))
    let LoggedOut = BBCUser()

    var userDefaults: UserDefaults!
    var device: MockEchoDevice!
    var webviewCookieManager: MockWebviewCookieManager!

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "testDefaults")
        device = MockEchoDevice(userDefaults: userDefaults).withEnabledSuperclassSpy()
        webviewCookieManager = MockWebviewCookieManager().withEnabledSuperclassSpy()

    }

    override func tearDown() {
        userDefaults.removeSuite(named: "testDefaults")
        super.tearDown()
    }

    func testPersistentIdentifiersShouldBeChangedIfHashedIDHasChanged() {
        userDefaults.set("aDifferentHashedID", forKey: UserDefaultsKeys.echoHashedID.rawValue)
        userDefaults.set(true, forKey: UserDefaultsKeys.echoSignedIn.rawValue)
        userDefaults.set("defaultValue", forKey: UserDefaultsKeys.echoDeviceID.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKeys.echoDeviceIDCreationDate.rawValue)

        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: false).setBBCUser(LoggedInPersonalisationOn)

        assertThat(userDefaults.string(forKey: UserDefaultsKeys.echoDeviceID.rawValue),
                not(presentAnd(equalTo("defaultValue"))))
        assertThat(userDefaults.string(forKey: UserDefaultsKeys.echoHashedID.rawValue),
                not(presentAnd(equalTo("aDifferentHashedID"))))
    }

    func testPersistentIdentifiersShouldBeChangedIfHardwareHasChanged() {
        userDefaults.set("1234", forKey: UserDefaultsKeys.echoHashedID.rawValue)
        userDefaults.set(true, forKey: UserDefaultsKeys.echoSignedIn.rawValue)
        userDefaults.set("defaultValue", forKey: UserDefaultsKeys.echoDeviceID.rawValue)
        userDefaults.set("1", forKey: UserDefaultsKeys.echoHardwareID.rawValue)
        userDefaults.set(Date().timeIntervalSince1970, forKey: UserDefaultsKeys.echoDeviceIDCreationDate.rawValue)

        stub(device) { stub in
            when(stub.getDeviceID()).thenReturn("2")
        }

        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: false).setBBCUser(LoggedInPersonalisationOn)

        assertThat(userDefaults.string(forKey: UserDefaultsKeys.echoDeviceID.rawValue),
                not(presentAnd(equalTo("defaultValue"))))
        assertThat(userDefaults.string(forKey: UserDefaultsKeys.echoHardwareID.rawValue),
                presentAnd(equalTo("2")))
    }

    func testDeviceIDGeneratedIfDeviceIDHasExpired() {
        userDefaults.set(1, forKey: UserDefaultsKeys.echoDeviceIDCreationDate.rawValue)
        userDefaults.set("some-device-id", forKey: UserDefaultsKeys.echoDeviceID.rawValue)

        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: false).setBBCUser(LoggedInExpiredToken)

        assertThat(userDefaults.string(forKey: UserDefaultsKeys.echoDeviceID.rawValue),
                not(presentAnd(equalTo("some-device-id"))))
    }

    func testDeviceIDCreationDateGeneratedIfDeviceIDHasExpired() {
        userDefaults.set("1234", forKey: UserDefaultsKeys.echoHashedID.rawValue)
        userDefaults.set(true, forKey: UserDefaultsKeys.echoSignedIn.rawValue)

        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: false).setBBCUser(LoggedInPersonalisationOn)

        assertThat(userDefaults.double(forKey: UserDefaultsKeys.echoDeviceIDCreationDate.rawValue), present())
        assertThat(userDefaults.bool(forKey: UserDefaultsKeys.echoSignedIn.rawValue), presentAnd(equalTo(true)))
    }

    func testShouldGenerateADeviceIDIfOneNotPresent() {
        let helper = UserPromiseHelper(device: device,
                                       webviewCookiesEnabled: false)
        assertThat(helper.getDeviceID(), not(nilValue()))
    }

    func testShouldGetTheExistingDeviceIDIfPresent() {
        userDefaults.set("some-device-id", forKey: UserDefaultsKeys.echoDeviceID.rawValue)
        let helper = UserPromiseHelper(device: device,
                                       webviewCookiesEnabled: false)
        assertThat(helper.getDeviceID()!, equalTo("some-device-id"))
    }
    
    func testSettingBBCUserWithCookiesEnabledCreatesCookie() {
        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: true).setBBCUser(LoggedInExpiredToken)

        //verify(webviewCookieManager).setCookie(withName: "ckns_echo_device_id", value: any(), domain: ".bbc.co.uk")
    }
 
    func testSettingBBCUserWithComCookiesEnabledCreatesCookie() {
        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: true).setBBCUser(LoggedInExpiredToken)
        
       //verify(webviewCookieManager).setCookie(withName: "ckns_echo_device_id", value: any(), domain: ".bbc.com")
    }
    
    func testSettingBBCUserWithCookiesDisabledDoesNotCreateCookie() {
        _ = UserPromiseHelper(device: device,
                          webviewCookiesEnabled: false).setBBCUser(LoggedInExpiredToken)
        
        //verify(webviewCookieManager, never()).setCookie(withName: "s1", value: any(), domain: ".bbc.co.uk")
    }

}
