//
//  MediaTests.swift
//  Echo
//
//  Created by Mark Turner on 23/02/2017.
//  Copyright © 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

@testable import Echo

class MediaTests: XCTestCase {
    
    let validContentId = "video123"
    let validAvType = MediaAVType.video
    let validPipsType = PipsType.clip
    let validVersionId = "versionABC"
    let validClipId = "validClipId"
    let validEpisodeId = "validEpisodeId"
    let validServiceId = "bbc_one"
    let validVpId = "validVpId"
    let validMediaConsumptionMode = MediaConsumptionMode.live
    let validMediaRetrievalType = MediaRetrievalType.stream
    let validMediaset = "pc"
    let validSupplier = "mf_bidi_uk_hds"
    let validTransferFormat = "hds"
    
    var media: Media!
    
    override func setUp() {
        super.setUp()
        media = Media(avType: validAvType, consumptionMode: validMediaConsumptionMode)
    }
    
    func testConstructorSetsAvTypeAndConsumptionMode() {
        assertThat(media.avType, equalTo(validAvType))
        assertThat(media.consumptionMode, equalTo(validMediaConsumptionMode))
    }
    
    func testConstructorStoresValuesAndDefaultsLength() {
        media.versionID = validVersionId
        media.serviceID = validServiceId
        
        assertThat(media.avType, equalTo(validAvType))
        assertThat(media.versionID, presentAnd(equalTo(validVersionId)))
        assertThat(media.serviceID, presentAnd(equalTo(validServiceId)))
        assertThat(media.consumptionMode, equalTo(validMediaConsumptionMode))
        assertThat(media.retrievalType, equalTo(validMediaRetrievalType))
    }
        
    func testSetIdMethodsSetValidValues() {
        media.versionID = validVersionId
        media.clipID = validClipId
        media.episodeID = validEpisodeId
        media.serviceID = validServiceId
        media.vpID = validVpId
        
        assertThat(media.versionID, presentAnd(equalTo(validVersionId)))
        assertThat(media.clipID, presentAnd(equalTo(validClipId)))
        assertThat(media.episodeID, presentAnd(equalTo(validEpisodeId)))
        assertThat(media.serviceID, presentAnd(equalTo(validServiceId)))
        assertThat(media.vpID, presentAnd(equalTo(validVpId)))
    }
    
    func testConstructorSetsDefaultMediaLength() {
        // media is live
        assertThat(media.length, equalTo(0))
        
        let media2 = Media(avType: validAvType, consumptionMode: .download)
        assertThat(media2.length, equalTo(Media.DefaultMediaLength))
    }
    
    func testMediaPersistsValidLength() {
        media.length = 10
        assertThat(media.length, equalTo(10))
    }
    
    func testMediaAllowsUpdatesToLength() {
        media.length = 10
        assertThat(media.length, equalTo(10))
        media.length = 20
        assertThat(media.length, equalTo(20))
    }
    
    func testGetCloneClonesMedia() {
        let clone = media.getClone()
        assertThat(clone.avType, equalTo(media.avType))
        assertThat(clone.consumptionMode, equalTo(media.consumptionMode))
        assertThat(clone, not(equalTo(media)))
    }

    func testGetRetrievalTypeReturnsDownloadIfConsumptionModeIsDownload() {
        // media is live
        assertThat(media.retrievalType, equalTo(.stream))
        
        let media2 = Media(avType: validAvType, consumptionMode: .download)
        assertThat(media2.retrievalType, equalTo(.download))
    }
    
    func testUnpopulatedVersionIdRemainsNil() {
        // nil
        assertThat(media.versionID, nilValue())
        
        // empty string
        media.versionID = ""
        assertThat(media.versionID, nilValue())
        
        // whitespace string
        media.versionID = "    \t  "
        assertThat(media.versionID, nilValue())
    }
    
    func testUnpopulatedServiceIdRemainsNil() {
        // nil
        assertThat(media.serviceID, nilValue())
        
        // empty string
        media.serviceID = ""
        assertThat(media.serviceID, nilValue())
        
        // whitespace string
        media.serviceID = "    \t  "
        assertThat(media.serviceID, nilValue())
    }

    func testMediaRetrievalModeOfDownloadIsDownload() {
        media.consumptionMode = .download
        XCTAssertEqual(media.retrievalType, .download)
    }

    func testMediaRetrievalModeOfLiveIsStream() {
        media.consumptionMode = .live
        XCTAssertEqual(media.retrievalType, .stream)
    }

    func testMediaRetrievalModeOfOndemandIsStream() {
        media.consumptionMode = .onDemand
        XCTAssertEqual(media.retrievalType, .stream)
    }

    func testMediaShouldReturnCorrectMediaLegnthInSeconds() {
        let media = Media(avType: .video, consumptionMode: .onDemand)
        media.length = 600000

        XCTAssertEqual(media.getLengthInSeconds(), 600)
    }

    func testPrducerNameSetsProducer() {
        media.producerName = "BBC_radio_5_LIVE"
        XCTAssertEqual(media.producer, Producer.BBCRadio5Live)
    }

    func testPrducerNameIsCaseInsensitive() {
        media.producerName = "bbc_RADIO_5_live"
        XCTAssertEqual(media.producer, Producer.BBCRadio5Live)
    }

    func testInvalidPrducerNameDoesNotSetProducer() {
        media.producerName = "Invalid"
        XCTAssertEqual(media.producer, .undefined)
    }

    func testSetProducerWithMasterbrandSetsProducer() {
        media.setProducerByMasterbrand("BBC_AMHARIC_RADIO")
        XCTAssertEqual(media.producer, Producer.Amharic)
    }

    func testSetProducerWithMasterbrandNameIsCaseInsensitive() {
        media.setProducerByMasterbrand("BBC_AmhARic_RADio")
        XCTAssertEqual(media.producer, Producer.Amharic)
    }

    func testSetProducerWithMasterbrandNameWithInvalidNameDoesNotSetProducer() {
        media.setProducerByMasterbrand("Invalid")
        XCTAssertEqual(media.producer, .undefined)
    }
}
