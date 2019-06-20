//  Copyright © 2016 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
@testable import Echo

class EchoClientTests: XCTestCase {

    let dirtyAppName = " aBC_ dEF Ghk*&fd^-gd.g&sd.f*1d   "
    let cleanAppName = "abc-def-ghk-fd-gd-g-sd-f-1d"


    let dirtyKey1 = "    some.label_or-other    "
    let cleanedKey1 = "some_label_or_other"


    let dirtyKey2 = "_a~b-c}d.e_"
    let cleanedKey2 = "a_b_c_d_e"


    let dirtyKey3 = "  aBC_ dEF Ghk*&fd^-gd.g&sd.f*1d   "
    let cleanedKey3 = "abc_def_ghk_fd_gd_g_sd_f_1d"

    let cleanedKey4 = "a_valid_label"
    // No dirty key here

    let value1 = "value string.1"
    let value2 = "value string.2"
    let value3 = "value string.3"
    let value4 = "value string.4"


    let startCounterName = "test.start.page"


    let deviceId = "InternallyGeneratedId"
    let barbDeviceId = "InternallyGeneratedBarbId"


    let mediaOnDemandClip: Media = Media(avType: .video, consumptionMode: .onDemand)
    let mediaOnDemandEpisode: Media = Media(avType: .video, consumptionMode: .onDemand)
    let mediaLiveClip: Media = Media(avType: .video, consumptionMode: .live)
    let mediaLiveEpisode: Media = Media(avType: .video, consumptionMode: .live)
    let invalidMedia: Media = Media(avType: .video, consumptionMode: .onDemand)

    var client: EchoClient!

    var factoryMock: MockDefaultDelegateFactory!
    var brokerFactoryMock: MockBrokerFactory!
    var bbcUserMock: BBCUser!
    var deviceMock: MockEchoDevice!
    var mock1: MockEchoDelegateMock!
    var mock2: MockEchoDelegateMock!
    var mock3: MockATInternetDelegate!
    var mockLiveBroker: MockLiveBroker!
    var onDemandBrokerMock: MockOnDemandBroker!
    var playerDelegateMock: PlayerDelegateMock! //MockPlayerDelegate!

    let dictionaryCaptor = ArgumentCaptor<Dictionary<String, String>>()
    let optionalDictionaryCaptor = ArgumentCaptor<Dictionary<String, String>?>()
    let optionalConfig = ArgumentCaptor<Dictionary<EchoConfigKey, String>?>()
    let configCaptor = ArgumentCaptor<Dictionary<EchoConfigKey, String>>()
    let arrayCaptor = ArgumentCaptor<Array<String>>()

    var config = [EchoConfigKey: String]()
    var dirtyLabelsIn = [String: String]()

    var echoMocks:Array<EchoDelegate>!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        mediaOnDemandClip.versionID = "Version123"
        mediaOnDemandEpisode.versionID = "Version123"
        mediaOnDemandEpisode.length = 10000

        mediaLiveClip.versionID = "Version123"
        mediaLiveClip.serviceID = "bbc_one_london"

        mediaLiveEpisode.versionID = "Version123"
        mediaLiveEpisode.versionID = "bbc_one_london"

        brokerFactoryMock = MockBrokerFactory()
        bbcUserMock = BBCUser()
        deviceMock = MockEchoDevice().withEnabledSuperclassSpy()

        config[.echoEnabled] = "true"
        config[.atiEnabled] = "true"

        stub(deviceMock) { mock in
            when(mock.getDeviceID()).thenReturn(deviceId)
            when(mock.getOrientation()).thenReturn("landscape")
            when(mock.isScreenReaderEnabled()).thenReturn(true)
        }

        playerDelegateMock = PlayerDelegateMock()

        mock1 = MockEchoDelegateMock().withEnabledSuperclassSpy()
        mock2 = MockEchoDelegateMock().withEnabledSuperclassSpy()
        mock3 = MockATInternetDelegate().withEnabledSuperclassSpy()
        mock3.tag = MockATInternetTag().withEnabledSuperclassSpy()

        echoMocks = [mock1, mock2, mock3]

        factoryMock = MockDefaultDelegateFactory().withEnabledSuperclassSpy() //.spy(on: DefaultDelegateFactoryStub())

        stub(factoryMock) { mock in
            when(mock.getDelegates(any(), appType: any(), startCounterName: any(), device: any(), config: any(), bbcUser: any()))
                    .thenReturn(echoMocks)
        }

        dirtyLabelsIn[dirtyKey1] = value1
        dirtyLabelsIn[dirtyKey2] = value2
        dirtyLabelsIn[dirtyKey3] = value3
        dirtyLabelsIn[cleanedKey4] = value4


        config[EchoConfigKey.echoDebug] = "false"

        client = try? EchoClient(appName: cleanAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
        XCTAssertNotNil(client, "Failed to initialise echo client")

        onDemandBrokerMock = MockOnDemandBroker(playerDelegate: playerDelegateMock, playhead: PlayheadMock(), media: mediaOnDemandClip, onDemandProtocol : client).withEnabledSuperclassSpy()
        mockLiveBroker = MockLiveBroker(playerDelegate: playerDelegateMock, playhead: PlayheadMock(), media: mediaLiveEpisode, liveProtocol: client, schedule: nil).withEnabledSuperclassSpy()

        stub(brokerFactoryMock) { mock in
            when(mock.makeLiveBroker(any(), media: any(), essUrl: any(),
                                     liveProtocol: any(), useHttps: any(), essEnabled: any())).thenReturn(mockLiveBroker)

            when(mock.makeOnDemandBroker(any(), media: any(),
                                         onDemandProtocol: any())).thenReturn(onDemandBrokerMock)
        }
        
        client.setPlayerName("test")
        client.setPlayerVersion("1.0")
        client.setPlayerDelegate(playerDelegateMock)


        reset(mock1, mock2)

    }

    override func tearDown() {
        super.tearDown()
    }

    //helper function for tests
    func assertLabelsOutIncludeCleanedLabelsIn(labelsOut: [String: String]) {
        assertLabelKeysIncludeCleanedKeysIn(keysOut: Array(labelsOut.keys))

        XCTAssertEqual(value1, labelsOut[cleanedKey1])
        XCTAssertEqual(value2, labelsOut[cleanedKey2])
        XCTAssertEqual(value3, labelsOut[cleanedKey3])
        XCTAssertEqual(value4, labelsOut[cleanedKey4])
    }

    //helper function for tests
    func assertLabelKeysIncludeCleanedKeysIn(keysOut: [String]) {
        XCTAssertNotNil(keysOut)
        XCTAssertTrue(keysOut.contains(cleanedKey1))
        XCTAssertTrue(keysOut.contains(cleanedKey2))
        XCTAssertTrue(keysOut.contains(cleanedKey3))
        XCTAssertTrue(keysOut.contains(cleanedKey4))
    }

}

