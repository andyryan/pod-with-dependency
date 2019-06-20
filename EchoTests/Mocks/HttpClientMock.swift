//
// Created by Adam Price - myBBC on 13/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation

class HttpClientMock: HttpClientProtocol {

    var getInvocationCount = 0

    func get() {
        getInvocationCount += 1
    }

}
