//
// Created by Adam Price - myBBC on 12/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

class LiveProtocolMock: LiveProtocol {

    var liveTimestampInvocationCallCount: Int = 0
    var liveMediaUpdateInvocationCount: Int = 0

    var liveMediaUpdateMedia: Media!
    var liveMediaOldPosition: UInt64!
    var liveMediaNewPosition: UInt64!

    func liveTimestampUpdate(_ timestamp: TimeInterval) {
        liveTimestampInvocationCallCount += 1
    }

    func setEssSuccess(_ isSuccess: Bool) {

    }

    func liveMediaUpdate(_ media: Media, newPosition: UInt64, oldPosition: UInt64) {
        liveMediaUpdateInvocationCount += 1
        liveMediaUpdateMedia = media
        liveMediaNewPosition = newPosition
        liveMediaOldPosition = oldPosition
    }

    func setEssError(_ error: EssError, code: String) {

    }

    func releaseSuppressedPlay() {

    }

    func sendHeartbeat(withName name: String, position: UInt64) {
        
    }

}
