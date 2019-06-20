//
//  MediaIdTests.swift
//  Echo
//
//  Created by Mark Turner on 28/02/2017.
//  Copyright © 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

@testable import Echo

class MediaIdTests: XCTestCase {

    let validValue = "valid-Value_09"
    let invalidValue = " Some.invalid/value"
    let validNonPipsValue = "validNonPipsContentID"
    
    var mediaId: MediaID!
    var mediaIdNoValidation: MediaID!
    
    override func setUp() {
        super.setUp()
        mediaId = MediaID(IDType: .version, requiresValidation: true)
        mediaIdNoValidation = MediaID(IDType: .version, requiresValidation: false)
    }
    
    func testConstructorSetsIdType() {
        assertThat(mediaId.IDType, presentAnd(equalTo(.version)))
    }
    
    func testSetsValue() {
        mediaId.setValue(validValue)
        assertThat(mediaId.getValue(), presentAnd(equalTo(validValue)))

        mediaId.setValue(invalidValue)
        assertThat(mediaId.getValue(), presentAnd(equalTo(invalidValue)))
    }
    
    func testIsSetReturnsTrueWhenSet() {
        mediaId.setValue(validValue)
        assertThat(mediaId.isSet(), equalTo(true))
    }
    
    func testIsSetIsTrueEvenWhenInvalid() {
        mediaId.setValue(invalidValue)
        assertThat(mediaId.isSet(), equalTo(true))
    }
    
    func testIdIsNotValidIfSetValueNotCalled() {
        assertThat(mediaId.isValid(), equalTo(false))
    }
    
    func testIdIsNotValidIfValueInvalid() {
        mediaId.setValue(invalidValue)
        assertThat(mediaId.isValid(), equalTo(false))
    }
    
    func testSetsIdType() {
        mediaId.IDType = .episode
        assertThat(mediaId.IDType, equalTo(.episode))
    }
    
    func testSetIdTypeToNonPipsContentID() {
        mediaIdNoValidation.IDType = .nonPipsContentID
        assertThat(mediaIdNoValidation.IDType, equalTo(.nonPipsContentID))
    }
    
    func testReturnTrueIfNonPipsContentID() {
        mediaIdNoValidation.IDType = .nonPipsContentID
        mediaIdNoValidation.setValue(validNonPipsValue)
        assertThat(mediaIdNoValidation.getValue(), presentAnd(equalTo(validNonPipsValue)))
    }

}
