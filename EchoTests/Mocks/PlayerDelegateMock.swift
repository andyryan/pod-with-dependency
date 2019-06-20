//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

class PlayerDelegateMock: PlayerDelegate {

    var timestamp: TimeInterval!
    var position: UInt64!

    func getTimestamp() -> TimeInterval {
        return timestamp != nil ? timestamp : 0
    }

    func getPosition() -> UInt64 {
        return position != nil ? position : 0
    }

}
