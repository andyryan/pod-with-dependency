//
//  SpringDelegate.swift
//  Echo
//
//  Created by Adam Price - myBBC on 25/05/2016.
//  Copyright © 2016 BBC. All rights reserved.
//

import Foundation
#if os(tvOS)
import tvOSKMA_SpringStreams
#else
import KMA_SpringStreams
#endif

internal class SpringDelegate: NSObject {
}

private enum BARBStreamValue: String {

    case Download = "dwn"
    case OnDemand = "od"
    case LivePrefix = "live/"

}
