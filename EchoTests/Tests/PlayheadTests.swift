//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation
import XCTest
@testable import Echo

class PlayheadTests: XCTestCase {

    var playhead: Playhead!
    var mockClock: MockClock!

    override func setUp() {
        super.setUp()
        mockClock = MockClock()
        playhead = Playhead(clock: mockClock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCorrectReportingAfterOneHour() {
        mockClock.time = 10000
        playhead.start()
        mockClock.time = 10000 + 3600
        XCTAssertEqual(3600000, playhead.getPosition())
    }

    func testCorrectReportingWhenPaused() {
        let startTime = 1453718421.096
        mockClock.time = startTime
        playhead.start()
        mockClock.time = startTime + 900
        playhead.stop()
        mockClock.time = startTime + 1140
        playhead.start()
        mockClock.time = startTime + 1200
        playhead.stop()
        XCTAssertEqual(960000, playhead.getPosition())
    }

    func testCorrectReportingWhenClipIsPlaying() {
        let startTime = 1453718421.096
        mockClock.time = startTime
        playhead.start()
        mockClock.time = startTime + 1440
        XCTAssertEqual(1440000, playhead.getPosition())
    }

    func testPlayheadIsZeroBeforeStartIsCalled() {
        XCTAssertEqual(0, playhead.getPosition())
    }

    func testPlayheadIsZeroAfterReset() {
        playhead.reset()
        XCTAssertEqual(0, playhead.getPosition())
    }

}
