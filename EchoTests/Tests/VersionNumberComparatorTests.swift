//
// Created by Adam Price on 17/02/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import Cuckoo
import XCTest
import Hamcrest

@testable import Echo

class VersionNumberComparatorTests: XCTestCase {

    func testLowerFollowedByHigherReturnsNSOrderedAscending() {
        assertThat("11.0.1".compare(toVersion: "11.0.7"), equalTo(.orderedAscending))
    }

    func testHigherFollowedByLowerReturnsNSOrderedDescending() {
        assertThat("11.0.0".compare(toVersion: "10.0.0"), equalTo(.orderedDescending))
    }

    func testIdenticalVersionNumbersReturnNSOrderedSame() {
        assertThat("11.0.0".compare(toVersion: "11.0.0"), equalTo(.orderedSame))
    }

    func testDifferentLengthVersionNumbers() {
        assertThat("11.0.6.2".compare(toVersion: "11.0.7"), equalTo(.orderedAscending))
        assertThat("10.0.0.3".compare(toVersion: "10.0.0"), equalTo(.orderedDescending))
    }

}