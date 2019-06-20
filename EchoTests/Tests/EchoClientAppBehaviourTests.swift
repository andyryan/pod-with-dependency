//
// Created by James Owen on 15/04/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import Cuckoo
import Hamcrest
import XCTest

class EchoClientAppBehaviourTests: EchoClientTests {

    func testSetUp() {
        super.setUp()
    }

    func testConstructorUsesFactory() {

        // Factory asked to provide the delegates?
        verify(factoryMock).getDelegates(
                cleanAppName,
                appType: equal(to: ApplicationType.mobileApp),
                startCounterName: startCounterName,
                device: any(),
                config: configCaptor.capture(),
                bbcUser: any())

        // Config passed to the factory contained the correct keys?
        let configCaptorKeys = configCaptor.value!.keys
        let configKeys = config.keys

        for key in configKeys {
            assert(configCaptorKeys.contains(key))
        }
    }

    func testConstructorCreatesAndStoresDelegates() {

        // The Echo Client holds a reference to the delegates returned by
        // factory?
        assert(client.delegates[0] === mock1)
        assert(client.delegates[1] === mock2)
        assert(client.delegates[2] === mock3)

        assert(client.delegates.count == 3)
    }

    func testConstructorSetsCacheMode() {
        assert(client.getCacheMode() == EchoCacheMode.offline)
    }

// --Config defaults--------------------------------------------------------
    func testDebugModeDefaultsFalseIfJunkValueInProduction() {

        config[EchoConfigKey.echoDebug] = "junk"

        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        // Debug should have defaulted to false
        assert(!EchoDebug.isDebugEnabled)
    }

    func testCacheModeDefaultsToOFFLINE() {
        assert(EchoCacheMode.getEnum("blah") == EchoCacheMode.offline)
    }

// --Support Methods--------------------------------------------------------
    func testSetCacheModeSetsTheMode() {
        client.setCacheMode(.all)
        assert(client.getCacheMode() == .all)
        client.setCacheMode(.offline)
        assert(client.getCacheMode() == .offline)
    }

    func testSetCacheModeDelegates() {
        // Captor to grab the hash maps passed to delegates and the factory
        client.setCacheMode(.all)

        verify(mock1).setCacheMode(equal(to: EchoCacheMode.all))
        verifyNoMoreInteractions(mock1)
        verify(mock2).setCacheMode(equal(to: EchoCacheMode.all))
        verifyNoMoreInteractions(mock2)
    }

    func testSetCacheModeDoesNotDelegateAfterPlay() {
        client.viewEvent(counterName: "a.page", eventLabels: [String: String]())
        client.setMedia(mediaOnDemandEpisode)
        client.avPlayEvent(at: 0, eventLabels: nil)
        client.setCacheMode(.all)
        verify(mock1, never()).setCacheMode(equal(to: EchoCacheMode.all))
        verify(mock2, never()).setCacheMode(equal(to: EchoCacheMode.all))
    }

    func testSetCacheModeDelegatesAfterPlayThenEnd() {
        client.viewEvent(counterName: "a.page", eventLabels: [String: String]())
        client.setMedia(mediaOnDemandEpisode)
        client.avPlayEvent(at: 0, eventLabels: [String: String]())
        client.avEndEvent(at: 10, eventLabels: [String: String]())
        client.setCacheMode(.all)
        verify(mock1).setCacheMode(equal(to: EchoCacheMode.all))
        verify(mock2).setCacheMode(equal(to: EchoCacheMode.all))
    }

    func testFlushCacheDelegates() {
        verify(mock1, never()).flushCache()
        verify(mock2, never()).flushCache()
        client.flushCache()
        verify(mock1).flushCache()
        verify(mock2).flushCache()
    }

    func testSetContentLanguageDelgates() {
        verify(mock1, never()).setContentLanguage(anyString())
        verify(mock2, never()).setContentLanguage(anyString())
        client.setContentLanguage("L")
        verify(mock1).setContentLanguage("L")
        verify(mock2).setContentLanguage("L")
    }

    func testNonnilVersionNumbersAreReturned() {
        assert(client.getAPIVersion() != "")
    }

// -Echo Profile tests------------------------------------------------------

    func testDefaultClientConfigProfileIsSet() {

        verify(factoryMock).getDelegates(
                cleanAppName,
                appType: equal(to: ApplicationType.mobileApp),
                startCounterName: startCounterName,
                device: any(),
                config: configCaptor.capture(),
                bbcUser: any())

        XCTAssertNotNil(configCaptor.value)
        XCTAssertEqual("20982512", configCaptor.value![EchoConfigKey.comScoreCustomerIDKey])
        XCTAssertEqual("bd2a8394361ee741c8f79a2bbb532a06", configCaptor.value![EchoConfigKey.comScorePublisherSecret])
    }

    func testSetWorldServiceConfigWithProfile() {

        reset(factoryMock)

        config[EchoConfigKey.reportingProfile] = "world_service"

        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(factoryMock).getDelegates(
                cleanAppName,
                appType: equal(to: ApplicationType.mobileApp),
                startCounterName: startCounterName,
                device: any(),
                config: configCaptor.capture(),
                bbcUser: any())

        XCTAssertNotNil(configCaptor.value)
        XCTAssertEqual("20982512", configCaptor.value![EchoConfigKey.comScoreCustomerIDKey])
        XCTAssertEqual("bd2a8394361ee741c8f79a2bbb532a06", configCaptor.value![EchoConfigKey.comScorePublisherSecret])
    }

    func testKeepUserSpecifiedConfigWhenSettingProfile() {

        reset(factoryMock)

        config[EchoConfigKey.reportingProfile] = "world_service"
        config[EchoConfigKey.comScoreCustomerIDKey] = "12345678"

        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(factoryMock).getDelegates(
                cleanAppName,
                appType: equal(to: ApplicationType.mobileApp),
                startCounterName: startCounterName,
                device: any(),
                config: configCaptor.capture(),
                bbcUser: any())

        XCTAssertNotNil(configCaptor.value)
        XCTAssertEqual("12345678", configCaptor.value![EchoConfigKey.comScoreCustomerIDKey])
        XCTAssertEqual("bd2a8394361ee741c8f79a2bbb532a06", configCaptor.value![EchoConfigKey.comScorePublisherSecret])
    }

// -Application state methods----------------------------------------------
    func testAddPersistentLabelsCallsDelegates() {

        // MUT
        client.addLabels(dirtyLabelsIn)

        // Delegated to mock 1
        verify(mock1).addLabels(dictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: dictionaryCaptor.value!)

        // Delegated to mock 2
        verify(mock2).addLabels(dictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: dictionaryCaptor.value!)
    }

    func testAddPersistentLabelCallsDelegates() {

        // MUT
        client.addLabel(dirtyKey1, value: value1)

        // Delegated to mock 1 and label cleaned?
        verify(mock1).addLabels(dictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assert(1 == dictionaryCaptor.value!.count)
        assert(value1 == dictionaryCaptor.value![cleanedKey1])

        // Delegated to mock 2 and label cleaned?
        verify(mock2).addLabels(dictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assert(1 == dictionaryCaptor.value!.count)
        assert(value1 == dictionaryCaptor.value![cleanedKey1])
    }


// -Application event methods----------------------------------------------

    func testAppForegroundedCallsDelegates() {

        // MUT
        client.appForegrounded()

        /*
         * The first param to the delegates should be a nil counter name as
         * there is no prior call to view method. In production mode, the
         * application should not fall over - it should just pass a nil counter
         * name.
         */

        // Delegated to mock 1?
        verify(mock1).appForegrounded()
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).appForegrounded()
        verifyNoMoreInteractions(mock1)
    }

    func testAppBackgroundedCallsDelegates() {

        // MUT
        client.appBackgrounded()

        /*
         * The first param to the delegates should be a nil counter name as
         * there is no prior call to view method. In production mode, the
         * application should not fall over - it should just pass a nil counter
         * name.
         */

        // Delegated to mock 1?
        verify(mock1).appBackgrounded()
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).appBackgrounded()
        verifyNoMoreInteractions(mock1)
    }

// -Basic analytics methods------------------------------------------------

    func testSetCounterNameCallsDelegates() {

        // Clean, valid counter name as not testing cleanup functionality here.
        let counterIn = "news.page"

        // MUT
        client.setCounterName(counterIn)

        // Delegated to mock 1?
        verify(mock1).setCounterName(counterIn)

        // Delegated to mock 2?
        verify(mock2).setCounterName(counterIn)
    }

    func testViewEventCallsDelegates() {

        // Clean, valid counter name as not testing cleanup functionality here.
        let counterIn = "news.page"

        // MUT
        client.viewEvent(counterName: counterIn, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).viewEvent(counterName: counterIn, eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).viewEvent(counterName: counterIn, eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testErrorEventCallsDelegates() {

        let e = "Arrrghhhh. Snap. Awwwwwww!!"
        // MUT
        client.errorEvent(e, eventLabels: dirtyLabelsIn)

        /*
         * The first param to the delegates should be a nil counter name as
         * there is no prior call to view method. In production mode, the
         * application should not fall over - it should just pass a nil counter
         * name.
         */

        // Delegated to mock 1?
        verify(mock1).errorEvent(e, eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).errorEvent(e, eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testUserActionEventCallsDelegates() {

        let eventType = "aType"
        let eventDesc = "aName"

        //
        doViewPreReqs()

        // MUT
        client.userActionEvent(actionType: eventType, actionName: eventDesc, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).userActionEvent(actionType: eventType, actionName: eventDesc, eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).userActionEvent(actionType: eventType, actionName: eventDesc, eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testUserActionEventPreReqsViewEvent() {

        let eventType = "aType"
        let eventDesc = "aName"

        // No view event before the call to user action event

        // MUT
        client.userActionEvent(actionType: eventType, actionName: eventDesc, eventLabels: dirtyLabelsIn)

        // Shouldn't have been passed to the delegates
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testSanitizeLabelsHandlesMissingData() {

        // Dirty labels
        var out = client.sanitiseLabels(dirtyLabelsIn)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: out)


        // Dirty labels and empty key
        dirtyLabelsIn[""] = "abc"
        out = client.sanitiseLabels(dirtyLabelsIn)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: out)

        // Dirty labels and whitespace key
        dirtyLabelsIn["   "] = "abc"
        out = client.sanitiseLabels(dirtyLabelsIn)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: out)

    }

    func testSanitizeLabelsHandlesMissingData_SetVersion() {

        // Dirty labels
        var out = client.sanitiseLabels(dirtyLabelsIn)
        assertLabelKeysIncludeCleanedKeysIn(keysOut: Array(out.keys))

        // Dirty labels and empty key
        dirtyLabelsIn[""] = "abc"
        out = client.sanitiseLabels(dirtyLabelsIn)
        assertLabelKeysIncludeCleanedKeysIn(keysOut: Array(out.keys))

        // Dirty labels and whitespace key
        dirtyLabelsIn["   "] = "abc"
        out = client.sanitiseLabels(dirtyLabelsIn)
        assertLabelKeysIncludeCleanedKeysIn(keysOut: Array(out.keys))

    }

    func testSetTraceIdCallsDelegates() {

        // Set traceId
        client.setTraceID("test_delegate")

        let traceIdFirstDelegate = ArgumentCaptor<String>()
        let traceIdSecondDelegate = ArgumentCaptor<String>()
        let traceIdThirdDelegate = ArgumentCaptor<String>()

        // Check setTraceId is called on first delegate
        verify(mock1).setTraceID(traceIdFirstDelegate.capture())
        assert("test_delegate" == traceIdFirstDelegate.value!)

        // Check setTraceId is called on first second
        verify(mock2).setTraceID(traceIdSecondDelegate.capture())
        assert("test_delegate" == traceIdSecondDelegate.value!)

        // Check setTraceId is called on first second
        verify(mock3).setTraceID(traceIdThirdDelegate.capture())
        assert("test_delegate" == traceIdThirdDelegate.value!)
    }

    func testUserSpecifiedReportingConfigProfileStage() {
        // Reset mocks called in setup that we want to assert against
        reset(factoryMock)
        reset(deviceMock)

        stub(factoryMock) { mock in
            when(mock.getDelegates(any(), appType: any(), startCounterName: any(), device: any(), config: any(), bbcUser: any()))
                .thenReturn(echoMocks)
        }

        stub(deviceMock) { mock in
            when(mock.getDeviceID()).thenReturn(deviceId)
            when(mock.getOrientation()).thenReturn("landscape")
            when(mock.isScreenReaderEnabled()).thenReturn(true)
        }

        config[EchoConfigKey.echoDeviceID] = "SomeUniqueId"
        config[EchoConfigKey.reportingProfile] = "public_service_stage"
        config[EchoConfigKey.comScoreSite] = "stage"

        // MUT
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }


        // Check the config passed to the factory contained this value unchanged
        verify(factoryMock).getDelegates(
                cleanAppName,
                appType: equal(to: ApplicationType.mobileApp),
                startCounterName: startCounterName,
                device: any(),
                config: configCaptor.capture(),
                bbcUser: any())
        assert("public_service_stage" == configCaptor.value![EchoConfigKey.reportingProfile])
        assert("stage" == configCaptor.value![EchoConfigKey.comScoreSite])

    }

    func testIsEnabledByDefault() {
        assert(client.isEnabled() == true)
    }

    func testCanBeDisabledByConfig() {
        config[.echoEnabled] = "false"
        client = try? EchoClient(appName: cleanAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
        assert(client.isEnabled() == false)
    }

    func testCanBeDisabledInFlight() {
        assert(client.isEnabled() == true)
        client.disable()
        assert(client.isEnabled() == false)

        verify(mock1).clearMedia()
        verify(mock2).clearMedia()

        verify(mock1).disable()
        verify(mock2).disable()
    }

    func testCanBeEnabledInFlight() {
        config[.echoEnabled] = "false"
        client = try? EchoClient(appName: cleanAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
        assert(client.isEnabled() == false)

        client.enable()
        assert(client.isEnabled() == true)
        verify(mock1).enable()
        verify(mock2).enable()
    }

    func testAutoStartsByDefault() {
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(mock1).start()
        verify(mock2).start()
    }

    func testCanBeStartedManually() {
        config[.echoAutoStart] = "false"
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(mock1, never()).start()
        verify(mock2, never()).start()

        client.start()

        verify(mock1).start()
        verify(mock2).start()
    }

    func testEnableWillAutoStart() {
        config[.echoEnabled] = "false"
        config[.echoAutoStart] = "true"
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(mock1, never()).start()
        verify(mock2, never()).start()

        client.enable()

        verify(mock1).start()
        verify(mock2).start()
    }

    func testEnableWillNotAutoStart() {
        config[.echoEnabled] = "false"
        config[.echoAutoStart] = "false"
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(mock1, never()).start()
        verify(mock2, never()).start()

        client.enable()

        verify(mock1, never()).start()
        verify(mock2, never()).start()
    }

    func testStartWhileDisabledDoesNotStart() {
        config[.echoEnabled] = "false"
        config[.echoAutoStart] = "false"
        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(mock1, never()).start()
        verify(mock2, never()).start()

        client.start()

        verify(mock1, never()).start()
        verify(mock2, never()).start()
    }

    func doViewPreReqs() {
        client.viewEvent(counterName: "news.page", eventLabels: nil)
        reset(mock1, mock2)
    }

    func testSetDestinationCallsSetL1SiteOnATIDelegate(){
        let argumentCaptor : ArgumentCaptor<Destination> = ArgumentCaptor<Destination>()
        mock3.enable()
        mock3.start()
        client.setDestination(site: .CBBC)
        verify(mock3).setDestination(argumentCaptor.capture())
        verify(mock1).setDestination(any())
        verify(mock2).setDestination(any())
        assert(argumentCaptor.allValues[0] == .CBBC)
    }

    func testSetPublisherCallsSetL2SiteOnATIDelegate(){
        let argumentCaptor : ArgumentCaptor<Producer> = ArgumentCaptor<Producer>()
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducer(site: .BBC)
        verify(mock3).setProducer(argumentCaptor.capture())
        assert(argumentCaptor.allValues[0] == .BBC)
    }

    func testSetPublisherByNameCallsSetL2SiteOnATIDelegate() {
        let argumentCaptor : ArgumentCaptor<Producer> = ArgumentCaptor<Producer>()
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducer(name: "BBC_RADIO_5_LIVE")
        verify(mock3).setProducer(argumentCaptor.capture())
        assert(argumentCaptor.allValues[0] == .BBCRadio5Live)
    }

    func testSetPublisherByNameWithInvalidNameDoesNotSetL2() {
        let argumentCaptor : ArgumentCaptor<Producer> = ArgumentCaptor<Producer>()
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducer(name: "invalid")
        verify(mock3, never()).setProducer(argumentCaptor.capture())
    }

    func testSetPublisherByNameIsCaseInsensitive() {
        let argumentCaptor : ArgumentCaptor<Producer> = ArgumentCaptor<Producer>()
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducer(name: "BBC_radio_5_LIVE")
        verify(mock3).setProducer(argumentCaptor.capture())
        assert(argumentCaptor.allValues[0] == .BBCRadio5Live)
    }

    func testSetPublisherWithMasterbrandNameSetsl2SiteOnATIDelegate() {
        let argumentCaptor : ArgumentCaptor<Producer> = ArgumentCaptor<Producer>()
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducerByMasterbrand("BBC_SWAHILI_RADIO")
        verify(mock3).setProducer(argumentCaptor.capture())
        assert(argumentCaptor.allValues[0] == .Swahili)
    }

    func testSetPublisherWithMasterbrandNameWithInvalidNameDoesNotSetL2() {
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducerByMasterbrand("INVALID")
        verify(mock3, never()).setProducer(any())
    }

    func testSetPublisherWithMasterbrandNameIsCaseInsensitive() {
        let argumentCaptor : ArgumentCaptor<Producer> = ArgumentCaptor<Producer>()
        stub(mock3) { (mock) in
            when(mock.setProducer(any())).thenDoNothing()
        }
        client.setProducerByMasterbrand("BBC_SWaHIlI_radio")
        verify(mock3).setProducer(argumentCaptor.capture())
        assert(argumentCaptor.allValues[0] == .Swahili)
    }

    func testSetsBBCUserOnStartup() {
        let client: EchoClient

        do {
            client = try EchoClient(appName: dirtyAppName, appType: ApplicationType.mobileApp, startCounterName: startCounterName, config: config, echoDelegateFactory: factoryMock, device: deviceMock, brokerFactory: brokerFactoryMock, bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
            XCTAssertEqual(client.previousUser, bbcUserMock)
        } catch {
            XCTFail("Failed to initialise echo client")
        }
    }

    func testSetsBBCUserOnStartupWithId5Enabled() {
        config[.idv5Enabled] = "true"
        let client: EchoClient
        let argumentCaptor: ArgumentCaptor<BBCUser> = ArgumentCaptor<BBCUser>()

        do {
            client = try EchoClient(appName: dirtyAppName,
                                    appType: ApplicationType.mobileApp,
                                    startCounterName: startCounterName,
                                    config: config,
                                    echoDelegateFactory: factoryMock,
                                    device: deviceMock,
                                    brokerFactory: brokerFactoryMock,
                                    bbcUser: bbcUserMock)
            XCTAssertNotNil(client, "Failed to initialise echo client")
            XCTAssertEqual(client.previousUser, bbcUserMock)
        } catch {
            XCTFail("Failed to initialise echo client")
        }

        verify(mock1).updateBBCUserLabels(argumentCaptor.capture())
        XCTAssertEqual(bbcUserMock, argumentCaptor.value)
        verify(mock2).updateBBCUserLabels(argumentCaptor.capture())
        XCTAssertEqual(bbcUserMock, argumentCaptor.value)
        verify(mock3).updateBBCUserLabels(argumentCaptor.capture())
        XCTAssertEqual(bbcUserMock, argumentCaptor.value)
    }
}
