//
//  SpringSteam.swift
//  EchoTests
//
//  Created by Andrew Ryan on 28/08/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import Foundation
import KMA_SpringStreams

class SpringStreamProtocolMock: SpringStreamsProtocol{
    func track(_ stream: KMA_StreamAdapter & NSObjectProtocol, atts: [String : String]) -> KMA_Stream? {
        return nil
    }

    func unload() {

    }

    func setTimeout(_ timeout: TimeInterval) {

    }

    func getTimeout() -> TimeInterval {
        return 60.0
    }

    func setDebug(_ debug: Bool) {

    }

    func getDebug() -> Bool {
        return true
    }

    func getTracking() -> Bool {
        return true
    }

    func setTracking(_ tracking: Bool) {
        
    }


}
