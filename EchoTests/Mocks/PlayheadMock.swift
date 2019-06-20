//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

class PlayheadMock: PlayheadProtocol {

    var startInvocationCount: Int = 0
    var stopInvocationCount: Int = 0
    var resetInvocationCount: Int = 0
    var position: UInt64 = 0
    var timestamp: TimeInterval = 0

    func start() {
        startInvocationCount += 1
    }

    func stop() {
        stopInvocationCount += 1
    }

    func resetMock() {
        startInvocationCount = 0
        stopInvocationCount = 0
    }

    func reset() {
        resetInvocationCount += 1
    }

    func getPosition() -> UInt64 {
        return position
    }

    func getTimestamp() -> TimeInterval {
        return timestamp
    }

}
