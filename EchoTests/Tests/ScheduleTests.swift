//
// Created by Adam Price - myBBC on 13/06/2016.
// Copyright (c) 2016 BBC. All rights reserved.
//

import Foundation
import XCTest
@testable import Echo

class ScheduleTests: XCTestCase {

    var schedule: Schedule!
    var httpClientMock: HttpClientMock!
    var json: Data!

    override func setUp() {
        super.setUp()

        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "ess_sample", ofType: "json")!
        json = try? Data(contentsOf: URL(fileURLWithPath: path))

        httpClientMock = HttpClientMock()
        schedule = Schedule(httpClient: httpClientMock)
        schedule.fetchDataFromEss()
        schedule.didReceiveData(json)
    }

    func testScheduleQueryReturnsCorrectBroadcast() {
        let broadcast = schedule.query(1455290000)!
        XCTAssertEqual("b038nzy4", broadcast.versionId)
    }

    func testScheduleQueryReturnsNilOptionalIfNoBroadcastAtTime() {
        let broadcast = schedule.query(12345)
        XCTAssertNil(broadcast)
    }

    func testHasDataReturnsTrueWhenDataAvailable() {
        XCTAssertTrue(schedule.hasData())
    }

    func testHasDataReturnsFalseWhenDataNotAvailable() {
        schedule = Schedule(httpClient: httpClientMock)
        XCTAssertFalse(schedule.hasData())
    }

    func testMakesASingleRequestToEss() {
        XCTAssertEqual(1, httpClientMock.getInvocationCount)
    }

    func testSetsServiceIdFromResponse() {
        XCTAssertEqual("bbc_one_london", schedule.getServiceID())
    }

    func testErrorIsClearedAfterGetErrorIsCalled() {
        schedule.didEncounterError("timeout")
        var error = schedule.getError()
        XCTAssertNotNil(error)
        error = schedule.getError()
        XCTAssertNil(error)
    }

    func testTimeoutErrorIsSetCorrectly() {
        schedule.didEncounterError("timeout")
        let error = schedule.getError()
        XCTAssertEqual(EssError.Timeout, error!.0)
    }

    func testHttpStatusCodeSetCorrectlyOnError() {
        schedule.didEncounterError("500")
        let error = schedule.getError()
        XCTAssertEqual(EssError.StatusCode, error!.0)
        XCTAssertEqual("500", error!.1)
    }

    func testInvalidJsonResultsInJsonErrorBeingSet() {
        let dataString: NSString = "blahblahblah"
        let data: Data = dataString.data(using: String.Encoding.utf8.rawValue)!
        schedule.didReceiveData(data)
        let error = schedule.getError()
        XCTAssertEqual(EssError.JSON, error!.0)
    }

}
