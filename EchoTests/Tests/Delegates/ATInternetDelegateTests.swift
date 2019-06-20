//
//  ATInternetDelegateTests.swift
//  EchoTests
//
//  Created by Andrew Ryan on 31/08/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest
import Tracker

@testable import Echo

class ATInternetDelegateTests: XCTestCase {

    var invalidSiteId = "testSite"
    var delegate: ATInternetDelegate!
    var deviceMock: MockEchoDevice!

    var userPromiseHelper: UserPromiseHelper!
    var userPromiseHelperMock: MockUserPromiseMock!
    var cookieManagerMock: MockWebviewCookieManager!

    var mockAtiTag: MockATInternetTag!

    let validVersionID = "aValidVersionID"
    let validServiceID = "aValidServiceID"
    let validEpisodeID = "aValidEpisodeID"
    let validClipID = "aValidClipID"
    let validVPID = "aValidVPID"
    let validNonPipsContentID = "aValidNonPipsContentID"

    var mediaOnDemandVideoEpisode: Media!
    var mediaOnDemandAudioEpisode: Media!
    var mediaOnDemandClipOnSchedule: Media!
    var mediaLiveVideoClipOffSchedule: Media!
    var mediaLiveVideoEpisode: Media!
    var mediaLiveAudioEpisode: Media!

    let signedOut: BBCUser = BBCUser(signedIn: false, hashedID: nil, tokenRefreshTimestamp: nil)
    let signedIn: BBCUser = BBCUser(signedIn: true, hashedID: "unidentified-user", tokenRefreshTimestamp: nil)
    let signedInWithHid: BBCUser = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: nil)
    let signedinTokenExpired: BBCUser = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date(timeIntervalSinceNow: Date.aDayAgo))

    let liveLog = "a1"
    let liveCollectionDomain = "api.bbc.co.uk"

    var config = [
        EchoConfigKey.echoEnabled: "true",
        EchoConfigKey.atiLog: "test",
        EchoConfigKey.atiLogSSL: "testSSL",
        EchoConfigKey.keepAliveDuration: "3"
    ]

    var atiConfig: [String: String]!

    func setupMedia(){
        mediaOnDemandVideoEpisode = Media(avType: .video, consumptionMode: .onDemand)
        mediaOnDemandVideoEpisode.versionID = "ODvidEp456"
        mediaOnDemandVideoEpisode.episodeID = "Episode34"
        mediaOnDemandVideoEpisode.producer = Producer.BBCFour

        mediaOnDemandAudioEpisode = Media(avType: .audio, consumptionMode: .onDemand)
        mediaOnDemandAudioEpisode.versionID = "ODuadClip888"
        mediaOnDemandAudioEpisode.episodeID = "radio_one"
        mediaOnDemandAudioEpisode.producer = Producer.BBCOne

        mediaOnDemandClipOnSchedule = Media(avType: .video, consumptionMode: .onDemand)
        mediaOnDemandClipOnSchedule.versionID = "ODvidClip123"
        mediaOnDemandClipOnSchedule.producer = Producer.BBCHD

        mediaLiveVideoClipOffSchedule = Media(avType: .video, consumptionMode: .live)
        mediaLiveVideoClipOffSchedule.clipID = "LiveVidClip789"
        mediaLiveVideoClipOffSchedule.versionID = "Version421"
        mediaLiveVideoClipOffSchedule.serviceID = "bbc_one"
        mediaLiveVideoClipOffSchedule.producer = Producer.BBCNewsChannel

        mediaLiveVideoEpisode = Media(avType: .video, consumptionMode: .live)
        mediaLiveVideoEpisode.versionID = "LiveVidEp555"
        mediaLiveVideoEpisode.serviceID = "bbc_one"
        mediaLiveVideoEpisode.producer = Producer.BBCThree

        mediaLiveAudioEpisode = Media(avType: .audio, consumptionMode: .live)
        mediaLiveAudioEpisode.versionID = "LiveAudEp555"
        mediaLiveAudioEpisode.serviceID = "bbc_one"
        mediaLiveAudioEpisode.producer = Producer.BBCRadio1
    }
    
    override func setUp() {
        super.setUp()
        cookieManagerMock = MockWebviewCookieManager().withEnabledSuperclassSpy()
        deviceMock = MockEchoDevice().withEnabledSuperclassSpy()
        userPromiseHelper = UserPromiseHelper(device: deviceMock,
                                              webviewCookiesEnabled: false)
        userPromiseHelperMock = MockUserPromiseMock().withEnabledSuperclassSpy()
        setupMedia()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: invalidSiteId, device: deviceMock, config: config, bbcUser: BBCUser())
        mockAtiTag = MockATInternetTag().withEnabledSuperclassSpy()
        mockAtiTag.start()
        delegate.start()
        stub(mockAtiTag) { (stub) in
            when(stub.counterName).get.thenReturn("testCounterName")
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testTrackerIsInitialisedWithDefaultConfig() {
        var config = ATInternetDelegate.getDefaultConfig()
        config[.echoEnabled] = "true"
        let del = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: "596068", device: deviceMock, config: config, bbcUser: BBCUser())
        del.start()
        XCTAssertEqual(del.tag.tracker?.config["secure"]!, "true")
        XCTAssertEqual(del.tag.tracker?.config["site"]!, "596068")
    }

    func testTrackerIsInitilisedWithValidProductionSiteId(){
        let siteId = Destination.CBBC.toString()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: siteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertNotNil(delegate.tag.tracker)
        XCTAssertEqual(delegate.tag.tracker?.config["site"]!, siteId)
        XCTAssertEqual(delegate.tag.tracker?.config["domain"]!, liveCollectionDomain)
        XCTAssertEqual(delegate.tag.tracker?.config["log"]!, liveLog)
        XCTAssertEqual(delegate.tag.tracker?.config["logSSL"]!, liveLog)
        XCTAssertEqual(delegate.tag.level2, Destination.CBBC.defaultL2().rawValue)
    }

    func testTrackerIsInitilisedWithDefaultSiteId(){
        let siteId = Destination.Default.toString()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: siteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertNotNil(delegate.tag.tracker)
        XCTAssertEqual(delegate.tag.tracker?.config["site"]!, siteId)
        XCTAssertNotEqual(delegate.tag.tracker?.config["domain"]!, liveCollectionDomain)
        XCTAssertNotEqual(delegate.tag.tracker?.config["log"]!, liveLog)
        XCTAssertNotEqual(delegate.tag.tracker?.config["logSSL"]!, liveLog)
    }

    func testTrackerIsInitilisedWithValidTestSiteId(){
        let siteId = Destination.CBBCTest.toString()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: siteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertNotNil(delegate.tag.tracker)
        XCTAssertEqual(delegate.tag.tracker?.config["site"]!, siteId)
        XCTAssertNotEqual(delegate.tag.tracker?.config["domain"]!, "api.bbc.co.uk")
        XCTAssertNotEqual(delegate.tag.tracker?.config["log"]!, "a1")
        XCTAssertNotEqual(delegate.tag.tracker?.config["logSSL"]!, "a1")
        XCTAssertEqual(delegate.tag.level2, Destination.CBBC.defaultL2().rawValue)
    }

    func testTrackIsInitialisedWithInvalidL2SiteId() {
        config[.producer] = "this Is invalid"
        let siteId = Destination.CBBC.toString()
         delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: siteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertNotNil(delegate.tag.tracker)
        XCTAssertEqual(delegate.tag.tracker?.config["site"]!, Destination.CBBC.toString())
        XCTAssertEqual(delegate.tag.level2, Destination.CBBC.defaultL2().rawValue)
    }

    func testTrackerIsInitilisedWithValidL2SiteId(){
        config[.producer] = Producer.Bitesize.toString()
        let siteId = Destination.CBBC.toString()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: siteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertNotNil(delegate.tag.tracker)
        XCTAssertEqual(delegate.tag.tracker?.config["site"]!, Destination.CBBC.toString())
        XCTAssertEqual(delegate.tag.level2, Producer.Bitesize.rawValue)
        XCTAssertEqual(delegate.tag.level2, Producer.Bitesize.rawValue)
    }

    func testTrackIsInitialisedWithInvalidSiteId() {
        XCTAssertNotNil(delegate.tag.tracker)
        XCTAssertEqual(delegate.tag.tracker?.config["site"]!, "596068")
    }

    func testTrackerIsInitialisedWithConfig() {
        XCTAssertEqual(delegate.tag.tracker?.config["log"], config[EchoConfigKey.atiLog])
        XCTAssertEqual(delegate.tag.tracker?.config["logSSL"], config[EchoConfigKey.atiLogSSL])
    }

    func testViewEventCallsATInternetWithUnknownLabelsRemoved(){
        delegate.tag = mockAtiTag
        let argumentCaptor: ArgumentCaptor<[String: String]?> = ArgumentCaptor<[String:String]?>()
        let labelsIn = ["label.a": "value.a", "label.b": "value.b", "ess_value": "ess_value"]

        stub(mockAtiTag) { (mock) in
            when(mock.sendView(any())).thenDoNothing()
        }

        delegate.viewEvent(counterName: "test.page", eventLabels: labelsIn)
        verify(mockAtiTag).viewEvent(counterName: "test.page", eventLabels: argumentCaptor.capture())
        verify(mockAtiTag).sendView(any())
        let jsonString = mockAtiTag.lastCustomObject!.json
        let labelsOut = try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as! [String: String?]
        assertThat(argumentCaptor.allValues[0]!, containsLabels(labelsIn))
        XCTAssertFalse(labelsOut.contains(where: { (key, value) -> Bool in
            if key == "label.a" {
                return true
            }
            if key == "label.b"  {
                return true
            }
            return false
        }))
        XCTAssertTrue(labelsOut.contains(where: { (key, value) -> Bool in
            //keep ess values for debug purposes
            if key.starts(with: "ess_") && value == "ess_value" {
                return true
            }
            return false
        }))
    }

    func testPersistentLabelsAreNotIncludedInViewEvent(){
        delegate.tag = mockAtiTag
        let labelsIn = ["label.a": "value.a", "label.b": "value.b", "trace":"test_trace"]

        stub(mockAtiTag) { (mock) in
            when(mock.sendView(any())).thenDoNothing()
        }

        delegate.addLabels(labelsIn)
        delegate.viewEvent(counterName: "test.page", eventLabels: nil)
        verify(mockAtiTag).viewEvent(counterName: "test.page", eventLabels: isNil())
        verify(mockAtiTag).sendView(any())
        let jsonString = mockAtiTag.lastCustomObject!.json
        let labelsOut = try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as! [String: String?]
        XCTAssertFalse(labelsOut.contains(where: { (key, value) -> Bool in
            if key == "label.a" {
                return true
            }
            if key == "label.b" {
                return true
            }
            return false
        }))
        XCTAssertTrue(labelsOut.contains(where: { (key, value) -> Bool in
            //keep ess values for debug purposes
            if key == "trace" || key == "echo_event" {
                return true
            }
            return false
        }))
    }

    func testPlayEventCallsATInternet(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaOnDemandVideoEpisode)

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avPlayEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag).playEvent()
    }

    func testMultiplePlayEventsWithoutEndDontSend(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaOnDemandVideoEpisode)

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avPlayEvent(at: 1000, eventLabels: nil)
        mediaOnDemandVideoEpisode.isPlaying = true
        delegate.avPlayEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag, times(1)).playEvent()
    }

    func testBufferingSendsInfo(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaOnDemandVideoEpisode)
        mediaOnDemandVideoEpisode.isBuffering = false

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avBufferEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag).bufferingEvent(true)
    }

    func testPlayEventWhileBufferingSendsInfo(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaOnDemandVideoEpisode)
        mediaOnDemandVideoEpisode.isBuffering = true

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avPlayEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag, never()).playEvent()
        verify(mockAtiTag).bufferingEvent(false)
    }

    func testPauseEventCallsATInternet(){
        delegate.tag = mockAtiTag

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avPauseEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag).pauseEvent()
    }

    func testSeekEventCallsATInternet(){
        delegate.tag = mockAtiTag

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avSeekEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag).moveEvent()
    }

    func testEndEventCallsATInternet(){
        delegate.tag = mockAtiTag

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avEndEvent(at: 1000, eventLabels: nil)
        verify(mockAtiTag).stopEvent()
    }

    func testAddingOnDemandVideoCreatesRichMediaObject(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaOnDemandVideoEpisode)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLabel, mediaOnDemandVideoEpisode.versionID)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLevel2, mediaOnDemandVideoEpisode.producer.rawValue)
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme1, "brand=~series=~episode=Episode34~clip=~name=~type=~pList=")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme2, "retType=stream~init=~adEna=0")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme3, "mpN=~mpV=~tMod=~mlN=\(EchoClient.LibraryName)~mlV=\(EchoClient.LibraryVersion)")
        verify(mockAtiTag).addOnDemandVideo(label: mediaOnDemandVideoEpisode.versionID!, duration: Int(mediaOnDemandVideoEpisode.length / 1000))
    }

    func testAddingOnDemandAudioCreatesRichMediaObject(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaOnDemandAudioEpisode)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLabel, mediaOnDemandAudioEpisode.versionID)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLevel2, mediaOnDemandAudioEpisode.producer.rawValue)
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme1, "brand=~series=~episode=radio_one~clip=~name=~type=~pList=")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme2, "retType=stream~init=~adEna=0")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme3, "mpN=~mpV=~tMod=~mlN=\(EchoClient.LibraryName)~mlV=\(EchoClient.LibraryVersion)")
        verify(mockAtiTag).addOnDemandAudio(label: mediaOnDemandAudioEpisode.versionID!, duration: Int(mediaOnDemandAudioEpisode.length / 1000))
    }

    func testAddingLiveVideoCreatesRichMediaObject(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaLiveVideoEpisode)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLabel, mediaLiveVideoEpisode.versionID)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLevel2, mediaLiveVideoEpisode.producer.rawValue)
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme1, "brand=~series=~episode=~clip=~name=~type=~pList=bbc_one")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme2, "retType=stream~init=~adEna=0")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme3, "mpN=~mpV=~tMod=~mlN=\(EchoClient.LibraryName)~mlV=\(EchoClient.LibraryVersion)")
        verify(mockAtiTag).addLiveVideo(label: mediaLiveVideoEpisode.versionID!)
    }

    func testAddingLiveAudioCreatesRichMediaObject(){
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaLiveAudioEpisode)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLabel, mediaLiveAudioEpisode.versionID)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLevel2, mediaLiveAudioEpisode.producer.rawValue)
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme1, "brand=~series=~episode=~clip=~name=~type=~pList=bbc_one")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme2, "retType=stream~init=~adEna=0")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme3, "mpN=~mpV=~tMod=~mlN=\(EchoClient.LibraryName)~mlV=\(EchoClient.LibraryVersion)")
        verify(mockAtiTag).addLiveAudio(label: mediaLiveAudioEpisode.versionID!)
    }

    func testSettingMediaOverwritesOldMedia(){
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.setMedia(mediaLiveVideoEpisode)
        XCTAssertEqual(delegate.tag.richMedia?.mediaLabel, mediaLiveVideoEpisode.versionID)
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme1, "brand=~series=~episode=~clip=~name=~type=~pList=bbc_one")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme2, "retType=stream~init=~adEna=0")
        XCTAssertEqual(delegate.tag.richMedia?.mediaTheme3, "mpN=~mpV=~tMod=~mlN=\(EchoClient.LibraryName)~mlV=\(EchoClient.LibraryVersion)")
        XCTAssertEqual(delegate.tag.richMedia?.mediaLevel2, mediaLiveVideoEpisode.producer.rawValue)
    }

    func testConstructingMediaTheme1() {
        let media = mediaOnDemandVideoEpisode.getClone()
        media.brandID = "testBrandId"
        media.seriesID = "testSeriesId"
        media.episodeID = "testEpisodeId"
        media.clipID = "testClipId"
        media.name = "testMedia"
        media.type = MediaClipType.clip
        media.playlist = "testPlaylist"
        delegate.tag = mockAtiTag
        delegate.setMedia(media)
        verify(mockAtiTag).constructTheme1()
        let theme = delegate.tag.constructTheme1()
        XCTAssertEqual(theme, "brand=testBrandId~series=testSeriesId~episode=testEpisodeId~clip=testClipId~name=testMedia~type=clip~pList=testPlaylist")
    }

    func testConstructingMediaTheme1WithLiveMedia() {
        let media = mediaLiveVideoEpisode.getClone()
        media.brandID = "testBrandId"
        media.seriesID = "testSeriesId"
        media.episodeID = "testEpisodeId"
        media.clipID = "testClipId"
        media.name = "testMedia"
        media.type = MediaClipType.clip
        media.playlist = "testPlaylist"
        media.serviceID = "testServiceID"
        delegate.tag = mockAtiTag
        delegate.setMedia(media)
        verify(mockAtiTag).constructTheme1()
        let theme = delegate.tag.constructTheme1()
        XCTAssertEqual(theme, "brand=testBrandId~series=testSeriesId~episode=testEpisodeId~clip=testClipId~name=testMedia~type=clip~pList=testServiceID")
    }

    func testConstructingMediaTheme2() {
        let media = mediaOnDemandVideoEpisode.getClone()
        media.consumptionMode = .download
        media.initiationType = .auto
        media.adsEnabled = true
        delegate.tag = mockAtiTag
        delegate.setMedia(media)
        verify(mockAtiTag).constructTheme2()
        let theme = delegate.tag.constructTheme2()
        XCTAssertEqual(theme, "retType=download~init=auto~adEna=1")
    }

    func testConstructingMediaTheme3() {
        let media = mediaOnDemandVideoEpisode.getClone()
        media.mediaPlayerName = "testPlayerName"
        media.mediaPlayerVersion = "1.0-test"
        media.transportMode = "tMode"
        delegate.tag = mockAtiTag
        delegate.setMedia(media)
        verify(mockAtiTag).constructTheme3()
        let theme = delegate.tag.constructTheme3()
        XCTAssertEqual(theme, "mpN=testPlayerName~mpV=1.0-test~tMod=tMode~mlN=\(EchoClient.LibraryName)~mlV=\(EchoClient.LibraryVersion)")
    }

    func testShouldNotFireEventsWhenEventsDisabled(){
        delegate.disable()
        delegate.tag = mockAtiTag
        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }
        delegate.avPlayEvent(at: 1000, eventLabels: nil)
        delegate.avEndEvent(at: 1000, eventLabels: nil)
        delegate.avPauseEvent(at: 1000, eventLabels: nil)
        delegate.avSeekEvent(at: 1000, eventLabels: nil)

        delegate.userActionEvent(actionType: "action", actionName: "name", eventLabels: nil)
        delegate.userActionEvent(actionType: "action", actionName: "name", eventLabels: [ EchoLabelKeys.IsBackground.rawValue: "true"])
        delegate.avUserActionEvent(actionType: "action", actionName: EchoLabelKeys.EchoHeartbeat5Seconds.rawValue, position: 1000, eventLabels: nil)

        verify(mockAtiTag, never()).playEvent()
        verify(mockAtiTag, never()).stopEvent()
        verify(mockAtiTag, never()).pauseEvent()
        verify(mockAtiTag, never()).moveEvent()
        verify(mockAtiTag, never()).impressionEvent(eventLabels: any())
        verify(mockAtiTag, never()).touchEvent(eventLabels: any())
        verify(mockAtiTag, never()).send5SecondHeartbeat()
    }

    func testShouldFireEndEventWhenClearingPlayingMedia() {
        delegate.tag = mockAtiTag
        delegate.setMedia(mediaLiveVideoEpisode)

        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }

        delegate.avPlayEvent(at: 1000, eventLabels: nil)
        delegate.clearMedia()
        verify(mockAtiTag, times(1)).playEvent()
        verify(mockAtiTag).stopEvent()
    }

    func testSetL1SiteIdUpdatesL1SiteId() {
        delegate.tag = mockAtiTag
        delegate.setDestination(.CBBC)
        verify(mockAtiTag).setLevel1Site(siteId: Destination.CBBC.rawValue, completion: any())
    }

    func testsSettingChapterLabelsPopulatesChapterFieldsInViewEvents() {
        let argumentCaptor: ArgumentCaptor<Screen> = ArgumentCaptor<Screen>()
        delegate.tag = mockAtiTag
        addChapterLabels()
        delegate.viewEvent(counterName: "test.page", eventLabels: [
            "section": "testChapter1::testChapter2::testChapter3"
        ])
        stub(mockAtiTag) { (mock) in
            when(mock.sendView(any())).thenDoNothing()
        }
        verify(mockAtiTag).sendView(argumentCaptor.capture())
        XCTAssertEqual(argumentCaptor.allValues[0].chapter1, "testChapter1::testChapter2::testChapter3")
    }

    func testSettingContentIDLabelPopulatesCustomVarField() {
        let argumentCaptor: ArgumentCaptor<Screen> = ArgumentCaptor<Screen>()
        delegate.tag = mockAtiTag
        addChapterLabels()
        delegate.viewEvent(counterName: "test.page", eventLabels: [
            EchoLabelKeys.ContentId.rawValue: "testContentId"
        ])
        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }
        verify(mockAtiTag).setScreenCustomVariable(any(), 1, "testContentId")
        verify(mockAtiTag).sendView(argumentCaptor.capture())
    }

    func testSettingContentTypeLabelPopulatesCustomVarField() {
        let argumentCaptor: ArgumentCaptor<Screen> = ArgumentCaptor<Screen>()
        delegate.tag = mockAtiTag
        addChapterLabels()
        delegate.viewEvent(counterName: "test.page", eventLabels: [
            EchoLabelKeys.ContentType.rawValue: "testContentType"
        ])
        stub(mockAtiTag) { (mock) in
            when(mock.tracker.get).thenReturn(nil)
        }
        verify(mockAtiTag).setScreenCustomVariable(any(), 7, "testContentType")
        verify(mockAtiTag).sendView(argumentCaptor.capture())
    }

    func testSetL2SiteIdUpdatesLevel2SiteId() {
        delegate.tag = mockAtiTag
        delegate.setProducer(.CBBC)
        verify(mockAtiTag).setLevel2Site(siteId: Producer.CBBC.rawValue)
        XCTAssertEqual(mockAtiTag.level2, Producer.CBBC.rawValue)
        XCTAssertEqual(mockAtiTag.level2, Producer.CBBC.rawValue)
    }

    func testBBCUserWithoutHIDSetsUnidentifiedUser() {
        delegate.tag = mockAtiTag
        delegate.updateBBCUserLabels(signedIn)
        verify(mockAtiTag).setHashedUserId(signedIn.hashedID!)
    }

    func testBBCUserWithHIDSetsIdentifiedUser() {
        delegate.tag = mockAtiTag
        delegate.updateBBCUserLabels(signedInWithHid)
        verify(mockAtiTag).setHashedUserId(signedInWithHid.hashedID!)
    }
    
    func testBBCUserHasNoHIDWhenSignedOut() {
        delegate.tag = mockAtiTag
        delegate.updateBBCUserLabels(signedOut)
        verify(mockAtiTag, never()).setHashedUserId(any())
    }

    func testBBCUserHasExpiredToken() {
        delegate.tag = mockAtiTag
        delegate.updateBBCUserLabels(signedinTokenExpired)
        verify(mockAtiTag, never()).setHashedUserId(any())
        verify(mockAtiTag).removeHashedUserId()
    }

    func testDeviceIDSetsIDClient() {
        delegate.tag = mockAtiTag
        delegate.updateDeviceID("new_device_id")
        verify(mockAtiTag).setIDClient("new_device_id")
    }

    func addChapterLabels(){
        delegate.addLabels([
            "section": "testChapter1::testChapter2::testChapter3"
        ])
    }

    func testSetCacheModeAll() {
        delegate.tag = mockAtiTag
        let argumentcaptor = ArgumentCaptor<OfflineModeKey>()
        delegate.setCacheMode(.all)
        verify(mockAtiTag).setCacheMode(argumentcaptor.capture())
        XCTAssertEqual(argumentcaptor.value, OfflineModeKey.always)
    }

    func testSetCacheModeOffline() {
        delegate.tag = mockAtiTag
        let argumentcaptor = ArgumentCaptor<OfflineModeKey>()
        delegate.setCacheMode(.offline)
        verify(mockAtiTag).setCacheMode(argumentcaptor.capture())
        XCTAssertEqual(argumentcaptor.value, OfflineModeKey.required)
    }

    func testSetCacheModeAllInConfig() {
        config[.echoCacheMode] = EchoCacheMode.all.name()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: invalidSiteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertEqual(delegate.tag.tracker?.config["storage"], "always")
    }

    func testSetCacheModeOfflineInConfig() {
        config[.echoCacheMode] = EchoCacheMode.offline.name()
        delegate = ATInternetDelegate(appName: "echo_unit_tests", appType: .mobileApp, siteId: invalidSiteId, device: deviceMock, config: config, bbcUser: BBCUser())
        delegate.start()
        XCTAssertEqual(delegate.tag.tracker?.config["storage"], "required")
    }

    func testSettingDestinationToProductionSiteSetsDomain() {
        delegate.tag = mockAtiTag
        let e = expectation(description: "Did fire completion")
        stub(mockAtiTag) { (stub) in
            when(stub.setLevel1Site(siteId: any(), completion: any())).then({ (siteId, completion) in
                if let completion = completion {
                    completion()
                }
                e.fulfill()
            })
        }

        delegate.setDestination(.SportPS)
        waitForExpectations(timeout: 10) { (error) in
            verify(self.mockAtiTag).setDomain("api.bbc.co.uk")
            verify(self.mockAtiTag).setLog("a1", any())
        }
    }

    func testSettingDestinationToTestSiteDoesntSetDomain() {
        delegate.tag = mockAtiTag
        let e = expectation(description: "Did fire completion")
        stub(mockAtiTag) { (stub) in
            when(stub.setLevel1Site(siteId: any(), completion: any())).then({ (siteId, completion) in
                if let completion = completion {
                    completion()
                }
                e.fulfill()
            })
        }

        delegate.setDestination(.SportPSTest)
        waitForExpectations(timeout: 10) { (error) in
            verify(self.mockAtiTag).setDomain("ati-host.net")
        }
    }

    func testKeepAliveEventSetAtDuration(){
        delegate.tag = mockAtiTag
        XCTAssertEqual(delegate.keepAliveInterval, TimeInterval(3))
        let exists = NSPredicate { (_, _) -> Bool in
            return false
        }
        let e = expectation(for: exists, evaluatedWith: delegate, handler: nil)
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avPlayEvent(at: 0, eventLabels: nil)
        let _ = XCTWaiter.wait(for: [e], timeout: 5)
        verify(self.mockAtiTag).keepAliveEvent()
    }

    func testKeepAliveEventSendsCorrectProducer() {
        delegate.tag = mockAtiTag
        XCTAssertEqual(delegate.keepAliveInterval, TimeInterval(3))
        let exists = NSPredicate { (_, _) -> Bool in
            return false
        }
        let e = expectation(for: exists, evaluatedWith: delegate, handler: nil)
        mediaOnDemandVideoEpisode.producer = .BBC
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avPlayEvent(at: 0, eventLabels: nil)
        let _ = XCTWaiter.wait(for: [e], timeout: 5)
        let argumentCaptor = ArgumentCaptor<Screen>()
        verify(self.mockAtiTag).sendView(argumentCaptor.capture())
        XCTAssertEqual(argumentCaptor.value?.level2, Producer.BBC.rawValue)
    }

    func testKeepAliveEventSendsNoProducerWhenNoMediaProducerSet() {
        let mediaNoProducer = Media(avType: .video, consumptionMode: .onDemand)
        mediaNoProducer.versionID = "ODvidClip123"

        delegate.tag = mockAtiTag
        XCTAssertEqual(delegate.keepAliveInterval, TimeInterval(3))
        let exists = NSPredicate { (_, _) -> Bool in
            return false
        }
        let e = expectation(for: exists, evaluatedWith: delegate, handler: nil)
        delegate.setMedia(mediaNoProducer)
        delegate.avPlayEvent(at: 0, eventLabels: nil)
        let _ = XCTWaiter.wait(for: [e], timeout: 5)
        let argumentCaptor = ArgumentCaptor<Screen>()
        verify(self.mockAtiTag).sendView(argumentCaptor.capture())
        XCTAssertEqual(argumentCaptor.value?.level2, 0)
    }
    
    func testPlayerNameProvidedToDelegateIsAttachedToMedia() {
        delegate.tag = mockAtiTag
        let myMedia = Media(avType: .video, consumptionMode: .onDemand)
        let playerName = "myPlayerName"
        delegate.setPlayerName(playerName);
        delegate.setMedia(myMedia);

        let mediaCaptor = ArgumentCaptor<Media>()

        verify(self.mockAtiTag).addMedia(mediaCaptor.capture())
        XCTAssertEqual(mediaCaptor.value?.mediaPlayerName, playerName);
    }
    
    func testPlayerVersionProvidedToDelegateIsAttachedToMedia() {
        delegate.tag = mockAtiTag
        let myMedia = Media(avType: .video, consumptionMode: .onDemand)
        let playerVersion = "myPlayerVersion"
        delegate.setPlayerVersion(playerVersion);
        delegate.setMedia(myMedia);
        
        let mediaCaptor = ArgumentCaptor<Media>()
        
        verify(self.mockAtiTag).addMedia(mediaCaptor.capture())
        XCTAssertEqual(mediaCaptor.value?.mediaPlayerVersion, playerVersion);
    }
    
    func testMediaPlayerNameOnMediaOverridesPlayerNameOnDelegate() {
        delegate.tag = mockAtiTag
        let myMedia = Media(avType: .video, consumptionMode: .onDemand)
        let mediaPlayerName = "mediaPlayerName"
        let delegatePlayerName = "delegatePlayerName"
        myMedia.mediaPlayerName = mediaPlayerName
        delegate.setPlayerName(delegatePlayerName);
        delegate.setMedia(myMedia);
        
        let mediaCaptor = ArgumentCaptor<Media>()
        
        verify(self.mockAtiTag).addMedia(mediaCaptor.capture())
        XCTAssertEqual(mediaCaptor.value?.mediaPlayerName, mediaPlayerName);
    }
    
    func testMediaPlayerVersionOnMediaOverridesPlayerVersionOnDelegate() {
        delegate.tag = mockAtiTag
        let myMedia = Media(avType: .video, consumptionMode: .onDemand)
        let mediaPlayerVersion = "mediaPlayerVersion"
        let delegatePlayerVersion = "delegatePlayerVersion"
        myMedia.mediaPlayerVersion = mediaPlayerVersion
        delegate.setPlayerVersion(delegatePlayerVersion);
        delegate.setMedia(myMedia);
        
        let mediaCaptor = ArgumentCaptor<Media>()
        
        verify(self.mockAtiTag).addMedia(mediaCaptor.capture())
        XCTAssertEqual(mediaCaptor.value?.mediaPlayerVersion, mediaPlayerVersion);
    }

    func testUserActionEventWithBackgroundTrueSendsImpression() {
        stub(mockAtiTag) { (stub) in
            when(stub.impressionEvent(eventLabels: any())).thenDoNothing()
        }
        let argumentCaptor = ArgumentCaptor<[String: String]>()
        let eventLabels = [
            EchoLabelKeys.IsBackground.rawValue: "true"
        ]
        delegate.tag = mockAtiTag
        delegate.userActionEvent(actionType: "testActionType", actionName: "testActionName", eventLabels: eventLabels)
        verify(self.mockAtiTag).impressionEvent(eventLabels: argumentCaptor.capture())
        XCTAssertEqual("testActionType", argumentCaptor.value?[EchoLabelKeys.UserActionType.rawValue])
        XCTAssertEqual("testActionName", argumentCaptor.value?[EchoLabelKeys.UserActionName.rawValue])
    }

    func testUserActionEventWithoutBackgroundSendsTouch() {
        stub(mockAtiTag) { (stub) in
            when(stub.touchEvent(eventLabels: any())).thenDoNothing()
        }
        let argumentCaptor = ArgumentCaptor<[String: String]>()
        let eventLabels: [String: String] = [:]
        delegate.tag = mockAtiTag
        delegate.userActionEvent(actionType: "testActionType", actionName: "testActionName", eventLabels: eventLabels)
        verify(self.mockAtiTag).touchEvent(eventLabels: argumentCaptor.capture())
        XCTAssertEqual("testActionType", argumentCaptor.value?[EchoLabelKeys.UserActionType.rawValue])
        XCTAssertEqual("testActionName", argumentCaptor.value?[EchoLabelKeys.UserActionName.rawValue])
    }

    func testUserActionEventWithBackgroundFalseSendsTouch(){
        stub(mockAtiTag) { (stub) in
            when(stub.touchEvent(eventLabels: any())).thenDoNothing()
        }
        let argumentCaptor = ArgumentCaptor<[String: String]>()
        let eventLabels = [
            EchoLabelKeys.IsBackground.rawValue: "false"
        ]
        delegate.tag = mockAtiTag
        delegate.userActionEvent(actionType: "testActionType", actionName: "testActionName", eventLabels: eventLabels)
        verify(self.mockAtiTag).touchEvent(eventLabels: argumentCaptor.capture())
        XCTAssertEqual("testActionType", argumentCaptor.value?[EchoLabelKeys.UserActionType.rawValue])
        XCTAssertEqual("testActionName", argumentCaptor.value?[EchoLabelKeys.UserActionName.rawValue])
    }

    func testSetPublisherValues(){
        let eventLabels = [
            EchoLabelKeys.Container.rawValue: "testContainer",
            EchoLabelKeys.UserActionName.rawValue: "actionName",
            EchoLabelKeys.UserActionType.rawValue: "actionType",
            EchoLabelKeys.Personalisation.rawValue: "personalisation",
            EchoLabelKeys.Metadata.rawValue: "metaData",
            EchoLabelKeys.Source.rawValue: "source",
            EchoLabelKeys.Result.rawValue: "result",
        ]
        mockAtiTag.userId = "testUser"
        guard let tracker = mockAtiTag.tracker else {
            XCTFail()
            return
        }
        let publisher = tracker.publishers.add("testPublisher")
        mockAtiTag.setPublisherValues(publisher, eventLabels: eventLabels)

        XCTAssertEqual(publisher.creation, "[actionName~actionType]")
        XCTAssertEqual(publisher.campaignId, "[testContainer]")
        XCTAssertEqual(publisher.variant, "[personalisation]")
        XCTAssertEqual(publisher.format, "[metaData]")
        XCTAssertEqual(publisher.generalPlacement, "[testCounterName]")
        XCTAssertEqual(publisher.advertiserId, "[source]")
        XCTAssertEqual(publisher.url, "[result]")
        XCTAssertEqual(publisher.detailedPlacement, "[testUser]")
    }
    
    func testSetPublisherValuesWithEmptyAppType(){
        let eventLabels = [
            EchoLabelKeys.Container.rawValue: "testContainer",
            EchoLabelKeys.UserActionName.rawValue: "actionName",
            EchoLabelKeys.UserActionType.rawValue: "",
            EchoLabelKeys.Personalisation.rawValue: "personalisation",
            EchoLabelKeys.Metadata.rawValue: "metaData",
            EchoLabelKeys.Source.rawValue: "source",
            EchoLabelKeys.Result.rawValue: "result",
            ]
        mockAtiTag.userId = "testUser"
        guard let tracker = mockAtiTag.tracker else {
            XCTFail()
            return
        }
        let publisher = tracker.publishers.add("testPublisher")
        mockAtiTag.setPublisherValues(publisher, eventLabels: eventLabels)
        
        XCTAssertEqual(publisher.creation, "[actionName]")
    }

    func testSetPublisherValuesCleansesValues(){
        let eventLabels = [
            EchoLabelKeys.Container.rawValue: "test    Container",
            EchoLabelKeys.UserActionName.rawValue: "[actionName]",
            EchoLabelKeys.UserActionType.rawValue: "action&&Type",
            EchoLabelKeys.Personalisation.rawValue: "   personalisation   ",
            EchoLabelKeys.Metadata.rawValue: "meta  Data",
            EchoLabelKeys.Source.rawValue: "sou  rce  ",
            EchoLabelKeys.Result.rawValue: "[result]",
            ]
        mockAtiTag.userId = "testUser"
        guard let tracker = mockAtiTag.tracker else {
            XCTFail()
            return
        }
        let publisher = tracker.publishers.add("testPublisher")
        mockAtiTag.setPublisherValues(publisher, eventLabels: eventLabels)

        XCTAssertEqual(publisher.creation, "[actionName~action$$Type]")
        XCTAssertEqual(publisher.campaignId, "[test Container]")
        XCTAssertEqual(publisher.variant, "[personalisation]")
        XCTAssertEqual(publisher.format, "[meta Data]")
        XCTAssertEqual(publisher.generalPlacement, "[testCounterName]")
        XCTAssertEqual(publisher.advertiserId, "[sou rce]")
        XCTAssertEqual(publisher.url, "[result]")
        XCTAssertEqual(publisher.detailedPlacement, "[testUser]")
    }

    func testNoUserIdResultsInBlankDetailedPlacement(){
        let eventLabels = [
            EchoLabelKeys.Container.rawValue: "test    Container",
            EchoLabelKeys.UserActionName.rawValue: "[actionName]",
            EchoLabelKeys.UserActionType.rawValue: "action&&Type",
            EchoLabelKeys.Personalisation.rawValue: "   personalisation   ",
            EchoLabelKeys.Metadata.rawValue: "meta  Data",
            EchoLabelKeys.Source.rawValue: "sou  rce  ",
            EchoLabelKeys.Result.rawValue: "[result]",
        ]
        guard let tracker = mockAtiTag.tracker else {
            XCTFail()
            return
        }
        let publisher = tracker.publishers.add("testPublisher")
        mockAtiTag.setPublisherValues(publisher, eventLabels: eventLabels)

        XCTAssertEqual(publisher.creation, "[actionName~action$$Type]")
        XCTAssertEqual(publisher.campaignId, "[test Container]")
        XCTAssertEqual(publisher.variant, "[personalisation]")
        XCTAssertEqual(publisher.format, "[meta Data]")
        XCTAssertEqual(publisher.generalPlacement, "[testCounterName]")
        XCTAssertEqual(publisher.advertiserId, "[sou rce]")
        XCTAssertEqual(publisher.url, "[result]")
        XCTAssertEqual(publisher.detailedPlacement, "[]")
    }

    func testSetMediaLengthSetsRichMediaDuration() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.setMediaLength(UInt64(600000))
        XCTAssertEqual(delegate.tag.richMedia?.duration, 600)
    }

    func testSetCounterNameSetsLastScreen() {
        delegate.setCounterName("test.counter.name")
        XCTAssertEqual(delegate.tag.counterName, "test.counter.name")
        XCTAssertEqual(delegate.tag.lastScreen?.name, "test.counter.name")
    }
}
