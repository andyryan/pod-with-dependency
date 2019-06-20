//
// Created by James Owen on 03/02/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import KMA_SpringStreams

class KMA_StreamMock: KMA_Stream {

    @objc open var calledStop = false

    override func stop() {
        calledStop = true
    }

}
