//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

import XCTest
@testable import Echo

class LiveBrokerTests: XCTestCase {

    var liveBroker: LiveBroker!
    var playheadMock: PlayheadMock!
    var playerDelegateMock: PlayerDelegateMock!
    var scheduleMock: ScheduleMock!
    var liveProtocolMock: LiveProtocolMock!
    var broadcast: Broadcast!
    var media: Media!

    override func setUp() {
        super.setUp()

        scheduleMock = ScheduleMock()
        playheadMock = PlayheadMock()
        playerDelegateMock = PlayerDelegateMock()
        liveProtocolMock = LiveProtocolMock()

        broadcast = Broadcast(startTime: 12345, endTime: 1122345, episodeId: "epId",
                episodeTitle: "Sherlock", id: "1", versionId: "b038nzy4", brandTitle: "title")

        playerDelegateMock.timestamp = 12345
        scheduleMock.dataAvailable = true
        scheduleMock.broadcast = broadcast
        scheduleMock.serviceId = "bbc_one_wales"

        media = Media(avType: MediaAVType.video, consumptionMode: MediaConsumptionMode.live)
        media.serviceID = "bbc_one_wales"
        media.transportMode = "transportMode"
        media.mediaPlayerName = "playerName"
        media.mediaPlayerVersion = "1.0test"

        liveBroker = LiveBroker(playerDelegate: playerDelegateMock, playhead: playheadMock,
                media: media, liveProtocol: liveProtocolMock, schedule: scheduleMock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testUpdateScheduleOnlyCallsLiveTimestampUpdateIfTimestampHasChanged() {
        liveBroker.update()
        liveBroker.update()
        XCTAssertEqual(1, liveProtocolMock.liveTimestampInvocationCallCount)
    }

    func testUpdateScheduleUpdatesCurrentClipWhenBroadcastInfoIsFound() {
        liveBroker.update()
        XCTAssertEqual(1, liveProtocolMock.liveMediaUpdateInvocationCount)
    }

    func testUpdateScheduleReportsCorrectPreviousAndNewPositionsOnUpdate() {

        scheduleMock.reset()

        playerDelegateMock.timestamp = 1454565600000
        playheadMock.position = 1000

        liveBroker.update()
        playheadMock.position = 2000

        liveBroker.update()
        playheadMock.position = 5000

        let b = Broadcast(startTime: 1454565600000, endTime: 1454577300000, episodeId: "epId",
                episodeTitle: "BBC News", id: "1", versionId: "new_id", brandTitle: "title")

        scheduleMock.dataAvailable = true
        scheduleMock.broadcast = b

        liveBroker.update()

        XCTAssertEqual(5000, liveProtocolMock.liveMediaNewPosition)
        XCTAssertEqual(2000, liveProtocolMock.liveMediaOldPosition)
    }

    func testCallingStopStopsPlayhead() {
        liveBroker.stop()
        XCTAssertEqual(1, playheadMock.stopInvocationCount)
    }

    func testCallingStartStartsPlayhead() {
        liveBroker.start()
        XCTAssertEqual(1, playheadMock.startInvocationCount)
    }

    func testGetPositionReturnsLivePlayheadPosition() {
        playheadMock.position = 10000
        XCTAssertEqual(10000, liveBroker.getPosition())
    }

    func testGetTimestampReturnsLivePlayheadTimestamp() {
        playheadMock.position = 10000
        // Timestamp is in seconds on iOS
        XCTAssertEqual(10, liveBroker.getTimestamp())
    }

    func testCreatesNewMediaClipValuesWhenBroadcastIsFound() {
        playerDelegateMock.timestamp = 1455290000000
        liveBroker.update()
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.serviceID, "bbc_one_wales")
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.versionID, "b038nzy4")
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.avType, MediaAVType.video)
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.consumptionMode, MediaConsumptionMode.live)
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.transportMode, "transportMode")
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.mediaPlayerName, "playerName")
        XCTAssertEqual(liveProtocolMock.liveMediaUpdateMedia.mediaPlayerVersion, "1.0test")
    }

    func testMarksMediaObjectAsEnrichedByEss() {
        liveBroker.update()
        XCTAssertEqual(true, liveProtocolMock.liveMediaUpdateMedia.isEnrichedWithESSData)
    }

    func testDoesNotUpdateMediaWhenNoBroadcast() {
        scheduleMock.serviceId = "bbc_one_hd"
        scheduleMock.broadcast = nil
        liveBroker.update()
        XCTAssertEqual(0, liveProtocolMock.liveMediaUpdateInvocationCount)
    }

    func testUpdateMediaRestartsThePlayhead() {
        liveBroker.update()
        XCTAssertTrue(playheadMock.resetInvocationCount > 0)
    }

}
