//
// Created by Adam Price on 15/02/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

class OnDemandBrokerTests: EchoClientTests {

    var broker: OnDemandBroker!
    var media: Media!
    var playerDelegate: MockPlayerDelegateMock!
    var playhead: MockPlayheadMock!
    var onDemandProtocol: MockOnDemandProtocolMock!

    let heartbeatCaptor = ArgumentCaptor<String>()

    override func setUp() {
        super.setUp()

        playerDelegate = MockPlayerDelegateMock().withEnabledSuperclassSpy()
        playhead = MockPlayheadMock().withEnabledSuperclassSpy()
        onDemandProtocol = MockOnDemandProtocolMock().withEnabledSuperclassSpy()

        media = Media(avType: .video, consumptionMode: .onDemand)

        broker = OnDemandBroker(playerDelegate: playerDelegate, playhead: playhead, media: media,
                                onDemandProtocol: onDemandProtocol)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCallingStartStartsThePlayhead() {
        broker.start()
        verify(playhead, times(1)).start()
    }

    func testCallingStartMultipleTimesDoesNotMakeRepeatedCalls() {
        broker.start()
        broker.start()
        broker.start()
        verify(playhead, times(1)).start()
    }

    func testCallingStopStopsThePlayhead() {
        broker.start()
        broker.stop()
        verify(playhead, times(1)).stop()
    }

    func testCallingStopMultipleTimesDoesNotMakeRepeatedCalls() {
        broker.start()
        broker.stop()
        broker.stop()
        broker.stop()
        verify(playhead, times(1)).stop()
    }

    func testGetPositionReturnsPositionFromPlayhead() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(12345) }
        assertThat(broker.getPosition(), equalTo(12345))
    }

    func testGetTimestampReturnsZero() {
        assertThat(broker.getTimestamp(), equalTo(0))
    }

    func testSetPositionSetsInternalPosition() {
        broker.setPosition(12345)
        assertThat(broker.getPosition(), equalTo(12345))
    }

    func testSetPositionSetsCurrentIntervalMaxPosition() {
        broker.setPosition(12345)
        assertThat(broker.getCurrentIntervalMaxPosition(), equalTo(12345))
    }

    func testGetCurrentIntervalMaxPositionReturnsPlayerDelegatePosition() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(12345) }
        broker.update()
        assertThat(broker.getPosition(), equalTo(12345))
    }

    func testGetCurrentIntervalMaxPositionReturnsPlayerDelegatePositionAndPlayheadPosition() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(12345) }
        stub(playerDelegate) { stub in when(stub.getPosition()).thenReturn(12345) }
        broker.update()
        assertThat(broker.getPosition(), equalTo(24690))
    }

    func testArePositionsWithinToleranceReturnsTrueForTwoIdenticalValues() {
        XCTAssertTrue(broker.arePositionsWithinTolerance(firstPosition: 1, secondPosition: 1))
    }

    func testArePositionsWithinToleranceReturnsTrueForPlus1000MillisecondDifference() {
        XCTAssertTrue(broker.arePositionsWithinTolerance(firstPosition: 11500, secondPosition: 10000))
    }

    func testArePositionsWithinToleranceReturnsTrueForMinus1000MillisecondDifference() {
        XCTAssertTrue(broker.arePositionsWithinTolerance(firstPosition: 9500, secondPosition: 11000))
    }

    func testArePositionsWithinToleranceReturnsFalseForPlus1001MillisecondDifference() {
        XCTAssertFalse(broker.arePositionsWithinTolerance(firstPosition: 11501, secondPosition: 10000))
    }

    func testArePositionsWithinToleranceReturnsFalseForMinus1001MillisecondDifference() {
        XCTAssertFalse(broker.arePositionsWithinTolerance(firstPosition: 9500, secondPosition: 11001))
    }

    func testPauseEventSentWhenPositionReachesMediaLength() {
        media.length = 5000
        stub(playerDelegate) { stub in when(stub.getPosition()).thenReturn(10000) }

        // MUT
        broker.update()

        verify(onDemandProtocol).avPauseEvent(at: equal(to: 5000), eventLabels: optionalDictionaryCaptor.capture())
        assertThat(optionalDictionaryCaptor.value!!, containsLabels([EchoLabelKeys.EchoPauseAtMediaLength.rawValue: "1"]))
    }

    func testPauseEventNotSentWhenPositionIsLessThanMediaLength() {
        media.length = 10000
        stub(playerDelegate) { stub in when(stub.getPosition()).thenReturn(5000) }

        // MUT
        broker.update()

        verify(onDemandProtocol, never()).avPauseEvent(at: equal(to: 5000), eventLabels: any())
    }

    func testCallingUpdateOnMediaWithPlayingTime4000Sends3SecondsHeartbeat() {
        media.length = 10000
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(4000) }

        // MUT
        broker.update()

        verify(onDemandProtocol, times(1)).sendHeartbeat(withName: heartbeatCaptor.capture(), position: equal(to: 4000))
        assertThat(heartbeatCaptor.value!, equalTo(EchoLabelKeys.EchoHeartbeat3Seconds.rawValue))
    }

    func testCallingUpdateOnMediaWithPlayingTime2000DoesNotSend3SecondsHeartbeat() {
        media.length = 10000
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(2000) }

        // MUT
        broker.update()

        verify(onDemandProtocol, never()).sendHeartbeat(withName: heartbeatCaptor.capture(), position: equal(to: 2000))
    }

    func testCallingUpdateOnMediaWithPlayingTime6000Sends5SecondsHeartbeat() {
        media.length = 10000
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(6000) }

        // MUT
        broker.update()

        // this gets sent twice (with different names) because conditions for both 3 and 5 second hb are met
        // so we just check that the last one has the correct value
        verify(onDemandProtocol, atLeastOnce()).sendHeartbeat(withName: heartbeatCaptor.capture(), position: equal(to: 6000))
        assertThat(heartbeatCaptor.value!, equalTo(EchoLabelKeys.EchoHeartbeat5Seconds.rawValue))
    }

    func testCallingUpdateOnMediaWithPlayingTime4000DoesNotSend5SecondsHeartbeat() {
        media.length = 10000
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(4000) }

        // MUT
        broker.update()

        // it will send the first heartbeat so just have to check it isn't the 5 second one
        verify(onDemandProtocol, times(1)).sendHeartbeat(withName: heartbeatCaptor.capture(), position: equal(to: 4000))
        assertThat(heartbeatCaptor.value!, not(equalTo(EchoLabelKeys.EchoHeartbeat5Seconds.rawValue)))
    }
}
