//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

@testable import Echo

class ScheduleMock: ScheduleProtocol {
    var queryCallCount: Int = 0
    var broadcast: Broadcast?
    var dataAvailable: Bool = true
    var serviceId: String = "bbc_one_wales"

    func query(_ time: TimeInterval) -> Broadcast? {
        queryCallCount += 1
        return broadcast
    }

    func hasData() -> Bool {
        return true
    }

    func getError() -> (EssError, String)? {
        return nil
    }

    func getServiceID() -> String? {
        return serviceId
    }

    func reset() {
        queryCallCount = 0
        broadcast = nil
    }

}
