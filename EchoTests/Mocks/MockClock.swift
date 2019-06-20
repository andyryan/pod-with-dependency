//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

class MockClock: TimeProtocol {

    var time: TimeInterval = 0

    func currentTime() -> TimeInterval {
        return time
    }

}
