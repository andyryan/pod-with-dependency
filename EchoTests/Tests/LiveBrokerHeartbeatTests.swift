//
//  LiveBrokerHeartbeatTests.swift
//  Echo
//
//  Created by Mark Turner on 22/06/2017.
//  Copyright © 2017 BBC. All rights reserved.
//

// This file exists because for some reason the live broker tests are set up in a completely different way to the 
// on demand broker tests and this allows me to simply copy the heartbeat tests from there rather than entirely
// rewrite the existing live broker tests

import Foundation
import XCTest
import Cuckoo
import Hamcrest

class LiveBrokerHeartbeatTests: EchoClientTests {

    var broker: LiveBroker!
    var media: Media!
    var playerDelegate: MockPlayerDelegateMock!
    var playhead: MockPlayheadMock!
    var liveProtocol: MockLiveProtocolMock!
    var schedule: ScheduleMock!

    let heartbeatCaptor = ArgumentCaptor<String>()

    override func setUp() {
        super.setUp()

        playhead = MockPlayheadMock().withEnabledSuperclassSpy()
        playerDelegate = MockPlayerDelegateMock().withEnabledSuperclassSpy()
        liveProtocol = MockLiveProtocolMock().withEnabledSuperclassSpy()

        let broadcast = Broadcast(startTime: 12345, endTime: 1122345, episodeId: "epId",
                              episodeTitle: "Sherlock", id: "1", versionId: "b038nzy4", brandTitle: "title")

        schedule = ScheduleMock()
        schedule.dataAvailable = true
        schedule.broadcast = broadcast
        schedule.serviceId = "bbc_one_wales"

        DefaultValueRegistry.register(value:TimeInterval(1498128747), forType: TimeInterval.self)

        media = Media(avType: .video, consumptionMode: .live)

        broker = LiveBroker(playerDelegate: playerDelegate, playhead: playhead, media: media,
                                liveProtocol: liveProtocol, schedule: schedule)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCallingUpdateOnMediaWithPlayingTime4000Sends3SecondsHeartbeat() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(4000) }
        stub(playerDelegate) { stub in when(stub.getTimestamp()).thenReturn(4000) }

        // MUT
        broker.update()

        verify(liveProtocol, times(1)).sendHeartbeat(withName: heartbeatCaptor.capture(), position: any())
        assertThat(heartbeatCaptor.value!, equalTo(EchoLabelKeys.EchoHeartbeat3Seconds.rawValue))
    }

    func testCallingUpdateOnMediaWithPlayingTime2000DoesNotSend3SecondsHeartbeat() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(2000) }
        stub(playerDelegate) { stub in when(stub.getTimestamp()).thenReturn(2000) }

        // MUT
        broker.update()

        verify(liveProtocol, never()).sendHeartbeat(withName: heartbeatCaptor.capture(), position: any())
    }

    func testCallingUpdateOnMediaWithPlayingTime6000Sends5SecondsHeartbeat() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(6000) }
        stub(playerDelegate) { stub in when(stub.getTimestamp()).thenReturn(6000) }

        // MUT
        broker.update()

        // this gets sent twice (with different names) because conditions for both 3 and 5 second hb are met
        // so we just check that the last one has the correct value
        verify(liveProtocol, atLeastOnce()).sendHeartbeat(withName: heartbeatCaptor.capture(), position: any())
        assertThat(heartbeatCaptor.value!, equalTo(EchoLabelKeys.EchoHeartbeat5Seconds.rawValue))
    }

    func testCallingUpdateOnMediaWithPlayingTime4000DoesNotSend5SecondsHeartbeat() {
        stub(playhead) { stub in when(stub.getPosition()).thenReturn(4000) }
        stub(playerDelegate) { stub in when(stub.getTimestamp()).thenReturn(4000) }

        // MUT
        broker.update()

        // it will send the first heartbeat so just have to check it isn't the 5 second one
        verify(liveProtocol, times(1)).sendHeartbeat(withName: heartbeatCaptor.capture(), position: any())
        assertThat(heartbeatCaptor.value!, not(equalTo(EchoLabelKeys.EchoHeartbeat5Seconds.rawValue)))
    }
}
