//
// Created by James Owen on 03/02/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation

class BrokerMock: Broker {

    var calledGetTimestamp: Bool = false

    var pos: UInt64 = 0

    func start() {
    }

    func stop() {
    }

    func getCurrentIntervalMaxPosition() -> UInt64 {
        return 0
    }

    func setPosition(_ position: UInt64) {
    }

    func getRawTimestamp() -> TimeInterval {
        return 20
    }

    func getTimestamp() -> TimeInterval {
        calledGetTimestamp = true
        return 20
    }

    func getPosition() -> UInt64 {
        return self.pos
    }

    func setPosition(pos: UInt64) {
        self.pos = pos
    }

}
