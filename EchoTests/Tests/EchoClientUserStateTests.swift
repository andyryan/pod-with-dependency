//
//  EchoClientUserStateTests.swift
//  EchoTests
//
//  Created by Andrew Ryan on 09/11/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import XCTest
import ComScore
import Cuckoo
import Hamcrest

class EchoClientUserStateTests: XCTestCase {

    let appName = "App Name"
    let startCounterName = "test.start.page"
    var config = ComScoreDelegate.getDefaultConfig()
    var echoDeviceMock: MockEchoDevice!
    let delegate = MockEchoDelegateMock().withEnabledSuperclassSpy()

    let LoggedInPersonalisationOn = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
    let LoggedInPersonalisationOff = BBCUser(signedIn: true)
    let LoggedInExpiredToken = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date(timeIntervalSince1970: 1))
    let LoggedInNoTimestamp = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: nil)
    let LoggedOut = BBCUser()

    override func setUp() {
        echoDeviceMock = MockEchoDevice().withEnabledSuperclassSpy()
    }

    override func tearDown() {

    }

    func getMockClient(user: BBCUser, delegates: [EchoDelegate]) -> MockEchoClient {
        let client = try! MockEchoClient(appName: appName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: MockDefaultDelegateFactory().withEnabledSuperclassSpy(), device: echoDeviceMock, brokerFactory: MockBrokerFactory().withEnabledSuperclassSpy(), bbcUser: user).withEnabledSuperclassSpy()
        stub(client) { (mock) in
            when(mock.delegates.get).thenReturn(delegates)
        }
        return client
    }

    func testSetNewUserShouldUpdateBBCUserLabels() {
        config[.idv5Enabled] = "true"
        config[.echoAutoStart] = "false"

        let delegate = MockEchoDelegateMock().withEnabledSuperclassSpy()
        let userCaptor = ArgumentCaptor<BBCUser>()
        let user = BBCUser()
        let client = getMockClient(user: user, delegates: [delegate])
        client.start()

        reset(delegate)
        client.setBBCUser(user)
        stub(echoDeviceMock) { stub in
            when(stub.getDeviceID()).thenReturn("some-device-id")
        }

        verify(delegate).updateBBCUserLabels(userCaptor.capture())
        XCTAssertEqual(userCaptor.value, user)
    }

    func testCustomEventSentWhenUserStateChangeOccurs() {
        config[.idv5Enabled] = "true"
        config[.echoAutoStart] = "false"
        let client = getMockClient(user: BBCUser(), delegates: [delegate])
        let labelsCaptor = ArgumentCaptor<[String: String]?>()
        client.start()

        client.setBBCUser(BBCUser())
        stub(echoDeviceMock) { stub in when(stub.isNewInstall.get).thenReturn(false) }

        reset(delegate)

        client.setBBCUser(LoggedInPersonalisationOn)

        verify(delegate).userActionEvent(actionType: "user_state_change", actionName: "sign_in", eventLabels: labelsCaptor.capture())

        reset(delegate)
        client.setBBCUser(LoggedInPersonalisationOff)
        verify(delegate).userActionEvent(actionType: "user_state_change", actionName: "disable_personalisation", eventLabels: labelsCaptor.capture())
        assertThat(labelsCaptor.value!!, hasEntry("device_id_reset", "1"))

        reset(delegate)
        client.setBBCUser(LoggedInPersonalisationOn)
        verify(delegate).userActionEvent(actionType: "user_state_change", actionName: "enable_personalisation", eventLabels: labelsCaptor.capture())
        assertThat(labelsCaptor.value!!, hasEntry("device_id_reset", "1"))

        reset(delegate)
        client.setBBCUser(LoggedOut)
        verify(delegate).userActionEvent(actionType: "user_state_change", actionName: "sign_out", eventLabels: labelsCaptor.capture())
    }

    func testStateChangeEventReflectsPersonalisationAlso() {
        config[.idv5Enabled] = "true"
        config[.echoAutoStart] = "false"
        let labelsCaptor = ArgumentCaptor<[String: String]?>()
        let client = getMockClient(user: LoggedInPersonalisationOn, delegates: [delegate])

        config[.idv5Enabled] = "true"

        reset(delegate)
        client.start()

        client.setBBCUser(LoggedInPersonalisationOff)

        verify(delegate).userActionEvent(actionType: "user_state_change", actionName: "disable_personalisation", eventLabels: labelsCaptor.capture())
        assertThat(labelsCaptor.value!!, hasEntry("device_id_reset", "1"))
    }

    func testSetsBBCUserWhenEnabledAfterDisabledInitialisation() {
        let user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
        config[.echoEnabled] = "false"
        config[.echoAutoStart] = "false"
        config[.idv5Enabled] = "true"
        let labelsCaptor = ArgumentCaptor<BBCUser>()
        let client = getMockClient(user: user, delegates: [delegate])

        verify(delegate, never()).updateBBCUserLabels(any())
        reset(delegate)
        client.enable()
        client.start()

        verify(delegate).updateBBCUserLabels(labelsCaptor.capture())
        XCTAssertEqual(true, labelsCaptor.value?.signedIn)
        XCTAssertEqual("1234", labelsCaptor.value?.hashedID)

        client.disable()
        let user2 = BBCUser(signedIn: true, hashedID: "12345", tokenRefreshTimestamp: Date())
        client.setBBCUser(user2)
        client.enable()
        verify(delegate, times(2)).updateBBCUserLabels(labelsCaptor.capture())
        XCTAssertEqual("12345", labelsCaptor.value?.hashedID)
    }

    func testUserReset() {
        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "true"
        config[.echoAutoStart] = "false"

        let client = getMockClient(user: BBCUser(), delegates: [delegate])
        verify(delegate, never()).userStateChange()


        reset(delegate)

        client.start()
        client.setBBCUser(LoggedInPersonalisationOff)

        verify(delegate, atLeastOnce()).userStateChange()
    }

}
