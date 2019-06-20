//
// Created by James Owen on 19/01/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Hamcrest
import Cuckoo
import KMA_SpringStreams
@testable import Echo

class SpringDelegateTests: XCTestCase {

    let playerName = "unit_test_player"
    let playerVersion = "player_version_1"
    let appName = "App_Name"

    var delegate: SpringDelegate!

    var deviceMock: MockEchoDevice!

    var sensorMock: MockSpringStreamProtocolMock!

    var streamMock: KMA_StreamMock!

    var brokerMock: BrokerMock!

    let invalidMedia: Media = Media(avType: .video, consumptionMode: .onDemand)
    let mediaOnDemandEpisode: Media = Media(avType: .video, consumptionMode: .onDemand)
    let mediaLiveEpisode: Media = Media(avType: .video, consumptionMode: .live)
    let mediaDownloadedEpisode: Media = Media(avType: .video, consumptionMode: .download)
    let mediaLiveAudio: Media = Media(avType: .audio, consumptionMode: .live)

    var config = EchoClient.getDefaultConfig()

    override func setUp() {
        super.setUp()

        mediaOnDemandEpisode.versionID = "Version123"

        mediaLiveEpisode.versionID = "Version123"
        mediaLiveEpisode.serviceID = "bbc_one"

        mediaDownloadedEpisode.versionID = "Version123"
        mediaDownloadedEpisode.serviceID = "bbc_one"

        deviceMock = MockEchoDevice().withEnabledSuperclassSpy()
        sensorMock = MockSpringStreamProtocolMock().withEnabledSuperclassSpy()
        streamMock = KMA_StreamMock()
        brokerMock = BrokerMock()

        DefaultValueRegistry.register(value: streamMock, forType: KMA_Stream?.self)

        stub(sensorMock) { mock in
            when(mock.track(any(), atts: any())).thenReturn(streamMock)
        }
        stub(deviceMock) { mock in
            when(mock).getScreenWidth().thenReturn(1234)
            when(mock).getScreenHeight().thenReturn(4321)
        }

        config[.echoTrace] = "traceId"

        delegate = SpringDelegate(appName: "appName", springStreams: sensorMock, device: deviceMock, config: config)

        delegate.start()
    }

    func testShouldSetContentIdLabelWhenPrecedentSet() {
        let labelsCaptor = ArgumentCaptor<[String: String]>()
        prepareDelegateForPlayback()
        delegate?.avPlayEvent(at: 50, eventLabels: nil)
        verify(sensorMock).track(equal(to: delegate!), atts: labelsCaptor.capture())

        let values = labelsCaptor.value!

        assertThat(values, hasEntry(EchoLabelKeys.SpringStreamTypeKey.rawValue, "od"))
        assertThat(values, hasEntry(EchoLabelKeys.SpringStreamContentIDKey.rawValue, mediaOnDemandEpisode.versionID!))
    }

    func testShouldNotSetContentIdLabelWhenNoIds() {
        // Captor for the map passed to the sensor
        let mapCaptor = ArgumentCaptor<[String: String]>()

        //On demand piece of media is what's set up in this method
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(invalidMedia)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)

        //MUT
        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        // Intercept attributes passed to Spring's track event
        verify(sensorMock).track(equal(to: delegate!), atts: mapCaptor.capture())

        // Map contains expected info given on-demand media object provided in
        // prepareDelegateForPlayback()?
        let values = mapCaptor.value!

        assertThat(values, hasEntry(EchoLabelKeys.SpringStreamTypeKey.rawValue, "od"))
        assertThat(values, not(hasKey(EchoLabelKeys.SpringStreamContentIDKey.rawValue)))
    }

    func testConstructorSetsCacheMode() {
        assertThat(delegate?.getCacheMode(), presentAnd(equalTo(EchoCacheMode.offline)))
    }

    func testConstructorSetsTraceId() {
        reset(sensorMock)

        config[.echoTrace] = "test"

        let mapCaptor = ArgumentCaptor<[String: String]>()

        // Set up delegate with trace ID
        delegate = SpringDelegate(appName: appName, springStreams: sensorMock, device: deviceMock, config: config)
        delegate.start()
        prepareDelegateForPlayback()

        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        verify(sensorMock).track(equal(to: delegate!), atts: mapCaptor.capture())

        let values = mapCaptor.value!
        assertThat(values, hasEntry(EchoLabelKeys.EchoTrace.rawValue, "test"))
    }

    public func testChangeTraceIdOnSubsequentRequests() {

        reset(sensorMock)

        config[.echoTrace] = "test"

        let mapCaptor = ArgumentCaptor<[String: String]>()

        // Set up delegate with trace ID
        delegate = SpringDelegate(appName: appName, springStreams: sensorMock, device: deviceMock, config: config)
        delegate.start()
        prepareDelegateForPlayback()

        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        verify(sensorMock).track(equal(to: delegate!), atts: mapCaptor.capture())

        var values = mapCaptor.value!
        assertThat(values, hasEntry(EchoLabelKeys.EchoTrace.rawValue, "test"))

        reset(sensorMock)

        // Update trace ID and sent new play event
        delegate?.clearMedia()
        prepareDelegateForPlayback()
        delegate?.setTraceID("updated")
        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        verify(sensorMock).track(equal(to: delegate!), atts: mapCaptor.capture())

        // Check play event has updated trace ID
        values = mapCaptor.value!
        assertThat(values, hasEntry(EchoLabelKeys.EchoTrace.rawValue, "updated"))

    }

    func testSetCacheModeSetsTheMode() {
        delegate?.setCacheMode(.all)
        assertThat(delegate?.getCacheMode(), presentAnd(equalTo(EchoCacheMode.all)))
        delegate?.setCacheMode(.offline)
        assertThat(delegate?.getCacheMode(), presentAnd(equalTo(EchoCacheMode.offline)))
    }

    func testBackgroundEventDoesNothingIfStreamNotPlaying() {

        reset(sensorMock)
        // MUT
        delegate?.appBackgrounded()

        // Confirm the sensor has not been asked to play
        verify(sensorMock, never()).track(any(), atts: any())
        // Confirm the stream has not been invoked
        verifyNoMoreInteractions(sensorMock)
    }

    func testBackgroundEventStopsStreamIfPlaying() {
        // Set up delegate as if media is playing
        prepareDelegateForPlayback()
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // MUT
        delegate?.appBackgrounded()

        assertThat(streamMock.calledStop, equalTo(true))
    }

    func testBackgroundEventDoesNothingWithoutStream() {

        // Set up delegate as if media is playing
        prepareDelegateForPlayback()

        // Sets stream to null
        delegate?.avEndEvent(at: 50, eventLabels: nil)

        // MUT
        delegate?.appBackgrounded()

        assertThat(streamMock.calledStop, equalTo(false))
    }

    func testBackgroundEventStopsStreamInLiveMode() {

        // Set up delegate as if media is playing
        prepareDelegateForPlayback()

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // MUT
        delegate?.appBackgrounded()

        assertThat(streamMock.calledStop, equalTo(true))
    }

    func testPauseEventDoesNothingNonLiveMode() {

        // Set up delegate as if media is playing
        prepareDelegateForPlayback()

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaOnDemandEpisode)
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // MUT
        delegate?.avPauseEvent(at: 10, eventLabels: nil)

        assertThat(streamMock.calledStop, equalTo(false))
    }

    func testSetMediaNullsPreviousStream() {
        // Set up delegate as if media is playing
        prepareDelegateForPlayback()

        //Check no calls to Stream class on first call of setMedia
        verify(sensorMock, never()).track(any(), atts: any())
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        //Call set media second time, stop should be called.
        prepareDelegateForPlayback()
        delegate?.avPlayEvent(at: 0, eventLabels: nil)
        assertThat(streamMock.calledStop, equalTo(true))
    }

    func testPlayEventDoesNotCallTrackForInvalidMedia() {

        delegate?.setBroker(broker: brokerMock)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)
        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Confirm the sensor has been asked to play
        verify(sensorMock, never()).track(any(), atts: any())
    }

    func testPlayEventCallsTrackInLiveMode() {

        prepareDelegateForPlayback()

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)
        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Confirm the sensor has been asked to play
        verify(sensorMock).track(any(), atts: any())
    }

    func testPlayEventTracksForDownload() {

        prepareDelegateForPlayback()

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaDownloadedEpisode)
        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Confirm the sensor has been asked to play
        verify(sensorMock).track(any(), atts: any())
    }

    func testPlayEventTracksForOnDemand() {

        prepareDelegateForPlayback()

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaOnDemandEpisode)
        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Confirm the sensor has been asked to play
        verify(sensorMock).track(any(), atts: any())
    }

    func testPlayEventOnlyTracksOnce() {

        prepareDelegateForPlayback()

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaOnDemandEpisode)
        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)
        delegate?.avPlayEvent(at: 0, eventLabels: nil)
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Confirm the sensor has been asked to play
        verify(sensorMock).track(any(), atts: any())
    }

    func testPlayEventDoesNothingIfMandatoryDataNotProvided() {

        // Create CUT with debug disabled (live mode) via config
        config[.echoDebug] = "false"
        delegate = SpringDelegate(appName: appName, springStreams: sensorMock, device: deviceMock, config: config)
        delegate.start()

        delegate?.setMedia(mediaOnDemandEpisode)

        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Confirm the sensor has not been asked to play
        verify(sensorMock, never()).track(any(), atts: any())
    }

    func testPlayEventThrowsExceptionInDebugModeIfMandatoryDataNotProvided() {
//        todo: find a way to check for exception

//        config[.echoDebug] = "true"
//        delegate = SpringDelegate(appName: appName, springStreams: sensorMock, device: deviceMock, config: config)
//        delegate.start()
//
//        delegate.setMedia(mediaOnDemandEpisode)
//
//        delegate.avPlayEvent(at: 0, eventLabels: nil)
    }

    func testPlayEventCreatesStreamIfMandatoryDataProvided() {
        // Provide mandatory data
        prepareDelegateForPlayback()

        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)
        verify(sensorMock).track(any(), atts: any())
    }

    func testPlayEventPassesStreamAdapterCallbackToSpring() {
        // Provide mandatory data
        prepareDelegateForPlayback()

        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Delegate is passed in to sensor to provide callbacks?
        verify(sensorMock).track(equal(to: delegate!), atts: any())

    }

    func testPlayEventOperatesInOFFLINECacheMode() {
        // Provide mandatory data
        prepareDelegateForPlayback()

        delegate?.setCacheMode(EchoCacheMode.offline)

        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Delegate is passed in to sensor to provide callbacks?
        verify(sensorMock).track(equal(to: delegate!), atts: any())
    }

    func testPlayEventOperatesInAllCacheMode() {
        // Provide mandatory data
        prepareDelegateForPlayback()

        delegate?.setCacheMode(EchoCacheMode.all)

        // MUT
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // Delegate is passed in to sensor to provide callbacks?
        verify(sensorMock, never()).track(equal(to: delegate!), atts: any())
    }

    func testEendEventDoesNothingInOnDemandModeIfStreamNotPlaying() {
        // MUT
        reset(sensorMock)
        delegate?.avEndEvent(at: 50, eventLabels: nil)

        // Delegate is passed in to sensor to provide callbacks?
        verify(sensorMock, never()).track(any(), atts: any())

        verifyNoMoreInteractions(sensorMock)
    }

    func testEndEventStopsStreamInOnDemandModeIfPlaying() {
        // MUT
        prepareDelegateForPlayback()
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // MUT
        delegate?.avEndEvent(at: 0, eventLabels: nil)

        assertThat(streamMock.calledStop, equalTo(true))
    }

    func testEndEventDoesNothingInLiveMode() {

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)
        delegate?.avEndEvent(at: 0, eventLabels: nil)

        assertThat(streamMock.calledStop, equalTo(false))
    }

    func testSetMediaStopsStreamIfPlaying() {

        // Set up delegate as if media is playing
        prepareDelegateForPlayback()
        delegate?.avPlayEvent(at: 0, eventLabels: nil)

        // MUT
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)

        assertThat(streamMock.calledStop, equalTo(true))
    }

    func testMediaLengthCorrectlyMadeAvailableToSpring() {

        /*
         * Check value in original media object is available from getDuration and
         * then update media length and check new value is available (in seconds)
         */

        prepareDelegateForPlayback()

        let initialDuration = delegate?.getDuration()
        assertThat(Int32(mediaOnDemandEpisode.length / 1000), equalTo(initialDuration!))

        delegate?.setMediaLength(30 * 60 * 1000)

        let duration = delegate?.getDuration()
        assertThat(30 * 60, equalTo(duration!))
    }

    func testMediaLengthPassedToSpringIsZeroWhenLive() {

        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)

        let initialDuration = delegate?.getDuration()
        assertThat(0, equalTo(initialDuration!))

        delegate?.setMediaLength(30 * 60 * 1000)

        let duration = delegate?.getDuration()
        assertThat(0, equalTo(duration!))
    }

    func testPlayerNameCorrectlyMadeAvailableToSpring() {

        // MUT
        delegate?.setPlayerName(playerName)
        let updatedName = delegate?.getMeta().playername
        assertThat(playerName, equalTo((updatedName!)))
    }

    func testPlayerVersionCorrectlyMadeAvailableToSpring() {
        // MUT
        delegate?.setPlayerVersion(playerVersion)
        let updatedVersion = delegate?.getMeta().playerversion
        assertThat(playerVersion, equalTo((updatedVersion!)))
    }

    func testPlayerDelegateAndPlayheadPositionCorrectlyMadeAvailableToSpring() {

        delegate?.setMedia(mediaOnDemandEpisode)
        // MUT
        brokerMock.setPosition(pos: 1000)
        delegate?.setBroker(broker: brokerMock)
        let position = delegate?.getPosition()
        assertThat(1, equalTo(position!))

        brokerMock.setPosition(pos: 2000)
        delegate?.setBroker(broker: brokerMock)
        let position2 = delegate?.getPosition()
        assertThat(2, equalTo(position2!))

        brokerMock.setPosition(pos: 3000)
        delegate?.setBroker(broker: brokerMock)
        let position3 = delegate?.getPosition()
        assertThat(3, equalTo(position3!))
    }

    func testMandatoryDataItemsIncludeCallbackDelegate() {

        //Set other mandatory items besides callback delegate
        delegate?.setMedia(mediaOnDemandEpisode)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)

        //Delegate should report not all needed data available
        let isBarbDataAvailiable = delegate?.isBarbMandatedDataAvailable()
        assertThat(isBarbDataAvailiable!, equalTo(false))
    }

    func testMandatoryDataItemsIncludeMedia() {

        //Set other mandatory items besides callback delegate
        delegate?.setBroker(broker: brokerMock)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)

        //Delegate should report not all needed data available
        let isBarbDataAvailiable = delegate?.isBarbMandatedDataAvailable()
        assertThat(isBarbDataAvailiable!, equalTo(false))
    }

    func testMandatoryDataItemsIncludePlayerName() {

        //Set other mandatory items besides callback delegate
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaOnDemandEpisode)
        delegate?.setPlayerVersion(playerVersion)

        //Delegate should report not all needed data available
        let isBarbDataAvailiable = delegate?.isBarbMandatedDataAvailable()
        assertThat(isBarbDataAvailiable!, equalTo(false))
    }

    func testMandatoryDataItemsIncludePlayerVersion() {

        //Set other mandatory items besides callback delegate
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaOnDemandEpisode)
        delegate?.setPlayerName(playerName)

        //Delegate should report not all needed data available
        let isBarbDataAvailiable = delegate?.isBarbMandatedDataAvailable()
        assertThat(isBarbDataAvailiable!, equalTo(false))
    }

    func testScreenSizeCorrectlyMadeAvailiableToSpring() {
        assertThat(deviceMock.getScreenHeight(), equalTo(4321))
        assertThat(deviceMock.getScreenWidth(), equalTo(1234))
    }

    func testGetAttributesBuildsCorrectDataForOnDemandMedia() {

        // Captor for the map passed to the sensor
        let mapCaptor = ArgumentCaptor<[String: String]>()

        //On demand piece of media is what's set up in this method
        prepareDelegateForPlayback()

        //MUT
        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        // Intercept attributes passed to Spring's track event
        verify(sensorMock).track(equal(to: delegate!), atts: mapCaptor.capture())

        // Map contains expected info given on-demand media object provided in
        // prepareDelegateForPlayback()?
        let values = mapCaptor.value!
        assertThat(values, hasEntry(EchoLabelKeys.SpringStreamTypeKey.rawValue, "od"))
        let versionId = mediaOnDemandEpisode.versionID
        assertThat(values, hasEntry(EchoLabelKeys.SpringStreamContentIDKey.rawValue, versionId!))
    }

    func testGetAttributesBuildsCorrectDataForLiveMedia() {

        // Captor for the map passed to the sensor
        let mapCaptor = ArgumentCaptor<[String: String]>()

        //On demand piece of media is what's set up in this method
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)

        //MUT
        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        // Intercept attributes passed to Spring's track event
        verify(sensorMock).track(equal(to: delegate!), atts: mapCaptor.capture())

        // Map contains expected info given on-demand media object provided in
        // prepareDelegateForPlayback()?
        let values = mapCaptor.value!
        let versionId = mediaLiveEpisode.serviceID
        assertThat(values, hasEntry(EchoLabelKeys.SpringStreamTypeKey.rawValue, "live/" + versionId!))
    }

    func testAudioMediaObjectDoesNotCallSpringStreams() {
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveAudio)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)

        delegate?.avPlayEvent(at: 50, eventLabels: nil)

        verify(sensorMock, never()).track(equal(to: delegate!), atts: any())
    }

    func testGetPositionCallsTimestampWhenLive() {
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaLiveEpisode)

        _ = delegate?.getPosition()

        assertThat(brokerMock.calledGetTimestamp, equalTo(true))
    }

    func testCanBeDisabled() {
        delegate?.disable()

        delegate?.avEndEvent(at: 50, eventLabels: nil)

        verify(sensorMock, never()).track(any(), atts: any())
    }

    func testCanBeInitialisedAsDisabledThenEnabled() {
        config[.echoEnabled] = "false"
        setUp()
        prepareDelegateForPlayback()

        delegate.avPlayEvent(at: 50, eventLabels: nil)
        verify(sensorMock, never()).track(any(), atts: any())

        delegate.enable()
        prepareDelegateForPlayback()

        delegate.avPlayEvent(at: 50, eventLabels: nil)
        verify(sensorMock).track(any(), atts: any())
    }

    private func prepareDelegateForPlayback() {
        delegate?.setBroker(broker: brokerMock)
        delegate?.setMedia(mediaOnDemandEpisode)
        delegate?.setPlayerName(playerName)
        delegate?.setPlayerVersion(playerVersion)
    }
}
