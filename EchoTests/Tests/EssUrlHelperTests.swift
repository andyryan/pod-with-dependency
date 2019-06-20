//
// Created by Adam Price - myBBC on 13/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation
import XCTest
@testable import Echo

class EssUrlHelperTests: XCTestCase {

    var essHost = "ess.bbc.co.uk///"
    var media = Media(avType: MediaAVType.video, consumptionMode: MediaConsumptionMode.live)

    func testGeneratesUrlUsesServiceIdOverVersionIdAndVpid() {
        media.serviceID = "bbc_one_wales"
        let url = EssUrlHelper.generateEssUrl(essHost, media: media, useHttps: false)
        XCTAssertEqual("http://ess.bbc.co.uk/schedules?serviceId=bbc_one_wales", url)
    }

    func testGeneratesUrlUsesVersionIdWhenServiceIdNotSet() {
        media.versionID = "versionId"
        let url = EssUrlHelper.generateEssUrl(essHost, media: media, useHttps: false)
        XCTAssertEqual("http://ess.bbc.co.uk/schedules?versionId=versionId", url)
    }

    func testGeneratesUrlUsesVpidWhenVersionIdAndServiceIdNotSet() {
        media.vpID = "vpid"
        let url = EssUrlHelper.generateEssUrl(essHost, media: media, useHttps: false)
        XCTAssertEqual("http://ess.bbc.co.uk/schedules?vpid=vpid", url)
    }

    func testGeneratedUrlIsNilWhenNoSuitableIdIsProvided() {
        let url = EssUrlHelper.generateEssUrl(essHost, media: media, useHttps: false)
        XCTAssertNil(url)
    }
}
