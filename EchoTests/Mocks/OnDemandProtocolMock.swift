//
//  OnDemandProtocolMock.swift
//  EchoTests
//
//  Created by Andrew Ryan on 28/08/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import Foundation

class OnDemandProtocolMock: OnDemandProtocol {
    func sendHeartbeat(withName name: String, position: UInt64) {
        
    }

    func avPauseEvent(at position: UInt64, eventLabels: [String : String]?) {

    }

    
}
