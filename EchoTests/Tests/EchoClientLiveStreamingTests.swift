//
// Created by Adam Price - myBBC on 13/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation
import XCTest
@testable import Echo
import Cuckoo

class EchoClientLiveStreamingTests: EchoClientTests {
    var mockBrokerFactory: MockBrokerFactory!
    var mockPlayerDelegate: PlayerDelegateMock!


    override func setUp() {

        super.setUp()

        mockBrokerFactory = MockBrokerFactory().withEnabledSuperclassSpy()
        mockPlayerDelegate = PlayerDelegateMock()

        stub(mockBrokerFactory) { (mock) in
            when(mock.makeLiveBroker(any(), media: any(), essUrl: any(), liveProtocol: any(), useHttps: any(), essEnabled: any())).thenReturn(mockLiveBroker)
        }
        stub(mockBrokerFactory) { (mock) in
            when(mock.makeOnDemandBroker(any(), media: any(), onDemandProtocol: any())).thenReturn(onDemandBrokerMock)
        }

        DefaultValueRegistry.register(value: mockLiveBroker, forType: LiveBroker.self)
        DefaultValueRegistry.register(value: onDemandBrokerMock, forType: OnDemandBroker.self)
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: mockBrokerFactory, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        client.viewEvent(counterName: "news.page", eventLabels: nil)
        client.setPlayerName("test_player")
        client.setPlayerVersion("1.0")
        client.setPlayerDelegate(mockPlayerDelegate)

        stub(mockLiveBroker) { mlb in
            when(mlb.getPosition()).thenReturn(12345)
        }
        client.setMedia(mediaLiveEpisode)
    }

    func testSetMediaCreatesLiveBrokerWhenMediaIsLive() {
        verify(mockBrokerFactory).makeLiveBroker(
                any(),
                media : any(),
                essUrl: anyString(),
                liveProtocol: any(),
                useHttps: any(),
                essEnabled: any())
    }

    func testSetMediaDoesNotCreateLiveBrokerWhenMediaIsNotLive() {
        reset(mockBrokerFactory)
        client.setMedia(mediaOnDemandEpisode)
        verify(mockBrokerFactory, never()).makeLiveBroker(
                any(),
                media : any(),
                essUrl: anyString(),
                liveProtocol: any(),
                useHttps: any(),
                essEnabled: any())
    }

    func testAvPlayEventGetsPositionFromLiveBrokerWhenLive() {

        client.avPlayEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avPlayEvent(at: equal(to: 12345), eventLabels: any())
    }

    func testAvPlayEventStartsLiveBroker() {
        client.avPlayEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).start()
    }

    func testAvPauseEventGetsPositionFromLiveBrokerWhenLive() {

        client.avPauseEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avPauseEvent(at: equal(to: 12345), eventLabels: any())
    }

    func testAvPauseEventStopsLiveBroker() {
        client.avPauseEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).stop()
    }

    func testAvBufferEventGetsPositionFromLiveBrokerWhenLive() {

        client.avBufferEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avBufferEvent(at: equal(to: 12345), eventLabels: any())
    }

    func testAvBufferEventStopsLiveBroker() {
        client.avBufferEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).stop()
    }

    func testAvEndEventGetsPositionFromLiveBrokerWhenLive() {

        client.avEndEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avEndEvent(at: equal(to: 12345), eventLabels: any())
    }

    func testAvEndEventStopsLiveBroker() {
        client.avEndEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).stop()
    }

    func testAvRewindEventGetsPositionFromLiveBrokerWhenLive() {

        client.avRewindEvent(at: 10, rate: 2, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avRewindEvent(at: equal(to: 12345), rate: equal(to: 2), eventLabels: any())
    }

    func testAvRewindEventStopsLiveBroker() {
        client.avRewindEvent(at: 10, rate: 2, eventLabels: nil)

        verify(mockLiveBroker, times(1)).stop()
    }

    func testAvFastForwardEventGetsPositionFromLiveBrokerWhenLive() {

        client.avFastForwardEvent(at: 10, rate: 2, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avFastForwardEvent(at: equal(to: 12345), rate: equal(to: 2), eventLabels: any())
    }

    func testAvFastForwardEventStopsLiveBroker() {
        client.avFastForwardEvent(at: 10, rate: 2, eventLabels: nil)

        verify(mockLiveBroker, times(1)).stop()
    }

    func testAvSeekEventGetsPositionFromLiveBrokerWhenLive() {

        client.avSeekEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avSeekEvent(at: equal(to: 12345), eventLabels: any())
    }

    func testAvSeekEventStopsLiveBroker() {
        client.avSeekEvent(at: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).stop()
    }

    func testAvUserActionEventGetsPositionFromLiveBrokerWhenLive() {

        client.avUserActionEvent(actionType: "foo", actionName: "bar", position: 10, eventLabels: nil)

        verify(mockLiveBroker, times(1)).getPosition()

        verify(mock1).avUserActionEvent(actionType: equal(to: "foo"), actionName: equal(to: "bar"), position: equal(to: 12345), eventLabels: any())
    }

    func testLiveMediaUpdateCallsDelegates() {
        client.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)
        verify(mock1).liveMediaUpdate(any(), newPosition: equal(to: 100), oldPosition: equal(to: 200))
    }

    func testEssDisabledByDefault() {

        verify(mockBrokerFactory).makeLiveBroker(
                any(),
                media : any(),
                essUrl: anyString(),
                liveProtocol: any(),
                useHttps: any(),
                essEnabled: false)
    }

    func testEssEnabledFlagPassesTrueToLiveBroker() {

        clearInvocations(brokerFactoryMock)

        config[EchoConfigKey.useESS] = "true"

        do {
            client = try EchoClient(appName: cleanAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        client.viewEvent(counterName: "news.page", eventLabels: nil)
        client.setPlayerName("test_player")
        client.setPlayerVersion("1.0")
        client.setPlayerDelegate(playerDelegateMock)

        stub(mockLiveBroker) { mock in
            when(mock.getPosition()).thenReturn(12345)
        }

        client.setMedia(mediaLiveEpisode)

        verify(brokerFactoryMock).makeLiveBroker(
                any(),
                media : any(),
                essUrl: anyString(),
                liveProtocol: any(),
                useHttps: any(),
                essEnabled: true)
    }

    func testSetEssSuccessLabel() {

        reset(mock1)

        client.setEssSuccess(true)

        verify(mock1).addLabels(dictionaryCaptor.capture())

        assert("true" == dictionaryCaptor.value![EchoLabelKeys.ESSSuccess.rawValue]!)
    }

    func testSetEssErrorSetsErrorLabel() {

        reset(mock1)

        client.setEssError(EssError.StatusCode, code: "503")

        verify(mock1, times(2)).addLabels(dictionaryCaptor.capture())
        
        let labelsList : [[String:String]] = dictionaryCaptor.allValues

        let errorLabels : [String:String] = labelsList[0]
        let statusCodeLabels : [String : String] = labelsList[1]

        assert(EssError.StatusCode.rawValue == errorLabels[EchoLabelKeys.ESSError.rawValue])
        assert("503" == statusCodeLabels[EchoLabelKeys.ESSStatusCode.rawValue])
    }

    func testSetESSEnabledLabel() {
        reset(mock1)

        client.setMedia(mediaLiveEpisode)

        verify(mock1, times(1)).addLabels(dictionaryCaptor.capture())

        let labelsList : [[String:String]] = dictionaryCaptor.allValues

        let labels : [String:String] = labelsList[0]
        assert("false" == labels[EchoLabelKeys.ESSEnabled.rawValue])
    }
}
