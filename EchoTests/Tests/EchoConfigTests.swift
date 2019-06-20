//
//  EchoConfigTests.swift
//  EchoTests
//
//  Created by Andrew Ryan on 27/04/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import XCTest
@testable import Echo

class EchoConfigTests: EchoClientTests {
    
    let emptyAppName = ""
    let whiteSpaceAppname = "   "
    
    override func setUp() {
        super.setUp()
        config = [EchoConfigKey: String]()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testUsingEmptyApplicationNameThrows(){
        config[.echoDebug] = "true"
        XCTAssertThrowsError(try EchoClient(appName: emptyAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with empty app name")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: emptyAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with empty app name")
    }

    func testUsingWhiteSpaceApplicationNameThrows(){
        config[.echoDebug] = "true"
        XCTAssertThrowsError(try EchoClient(appName: whiteSpaceAppname,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid app name")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: whiteSpaceAppname,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid app name")
    }

    func testInvalidEnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.echoEnabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"enabled\" config")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"enabled\" config")
    }

    func testInvalidAutoStartConfigThrows(){
        config[.echoDebug] = "true"
        config[.echoAutoStart] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"autoStart\" config")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"autoStart\" config")
    }

    func testInvalidCacheModeConfigThrows(){
        config[.echoDebug] = "true"
        config[.echoCacheMode] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"cacheMode\" config")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"cacheMode\" config")
    }

    func testInvalidComscoreEnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.comScoreEnabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"comScoreEnabled\" config")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"comScoreEnabled\" config")
    }

    func testInvalidComscoreDebugConfigThrows(){
        config[.echoDebug] = "true"
        config[.comScoreDebugMode] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"comScoreDebugMode\"")
        
        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"comScoreDebugMode\"")
    }

    func testInvalidtestServiceEnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.testServiceEnabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"testServiceEnabled\"")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"testServiceEnabled\"")
    }

    func testInvalidUseEssConfigThrows(){
        config[.echoDebug] = "true"
        config[.useESS] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"useESS\"")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"useESS\"")
    }

    func testInvalidEssHttpsEnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.essHTTPSEnabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"essHTTPSEnabled\"")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"essHTTPSEnabled\"")
    }

    func testInvalidIdv5EnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.idv5Enabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"idv5Enabled\"")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"idv5Enabled\"")
    }

    func testInvalidWebCookiesEnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.webviewCookiesEnabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"webCookiesEnabled\"")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"webCookiesEnabled\"")
    }

    func testInvalidBarbEnabledConfigThrows(){
        config[.echoDebug] = "true"
        config[.barbEnabled] = "invalid"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"barbEnabled\"")

        config[.echoDebug] = "false"
        XCTAssertThrowsError(try EchoClient(appName: cleanAppName,
                                            appType: ApplicationType.mobileApp,
                                            startCounterName: startCounterName,
                                            config: config,
                                            echoDelegateFactory: factoryMock,
                                            device: deviceMock,
                                            brokerFactory: brokerFactoryMock,
                                            bbcUser: bbcUserMock),
                             "Client initialisation did not throw error with invalid \"barbEnabled\"")
    }

    func testEchoDebugConfig() {
        config[.echoDebug] = "true"
        let _ = try! EchoClient(appName: cleanAppName,
                                  appType: ApplicationType.mobileApp,
                                  startCounterName: startCounterName,
                                  config: config,
                                  echoDelegateFactory: factoryMock,
                                  device: deviceMock,
                                  brokerFactory: brokerFactoryMock,
                                  bbcUser: bbcUserMock)
        XCTAssertEqual(EchoDebug.level, EchoErrorLevel.warn)
        XCTAssertEqual(EchoDebug.isDebugEnabled, true)

        config[.echoDebug] = "info"
        let _ = try! EchoClient(appName: cleanAppName,
                                appType: ApplicationType.mobileApp,
                                startCounterName: startCounterName,
                                config: config,
                                echoDelegateFactory: factoryMock,
                                device: deviceMock,
                                brokerFactory: brokerFactoryMock,
                                bbcUser: bbcUserMock)
        XCTAssertEqual(EchoDebug.level, EchoErrorLevel.info)
        XCTAssertEqual(EchoDebug.isDebugEnabled, true)

        config[.echoDebug] = "warn"
        let _ = try! EchoClient(appName: cleanAppName,
                                appType: ApplicationType.mobileApp,
                                startCounterName: startCounterName,
                                config: config,
                                echoDelegateFactory: factoryMock,
                                device: deviceMock,
                                brokerFactory: brokerFactoryMock,
                                bbcUser: bbcUserMock)
        XCTAssertEqual(EchoDebug.level, EchoErrorLevel.warn)
        XCTAssertEqual(EchoDebug.isDebugEnabled, true)

        config[.echoDebug] = "error"
        let _ = try! EchoClient(appName: cleanAppName,
                                appType: ApplicationType.mobileApp,
                                startCounterName: startCounterName,
                                config: config,
                                echoDelegateFactory: factoryMock,
                                device: deviceMock,
                                brokerFactory: brokerFactoryMock,
                                bbcUser: bbcUserMock)
        XCTAssertEqual(EchoDebug.level, EchoErrorLevel.error)
        XCTAssertEqual(EchoDebug.isDebugEnabled, true)

        config[.echoDebug] = "false"
        let _ = try! EchoClient(appName: cleanAppName,
                                appType: ApplicationType.mobileApp,
                                startCounterName: startCounterName,
                                config: config,
                                echoDelegateFactory: factoryMock,
                                device: deviceMock,
                                brokerFactory: brokerFactoryMock,
                                bbcUser: bbcUserMock)
        XCTAssertEqual(EchoDebug.isDebugEnabled, false)

        config[.echoDebug] = "invalid"
        let _ = try! EchoClient(appName: cleanAppName,
                                appType: ApplicationType.mobileApp,
                                startCounterName: startCounterName,
                                config: config,
                                echoDelegateFactory: factoryMock,
                                device: deviceMock,
                                brokerFactory: brokerFactoryMock,
                                bbcUser: bbcUserMock)
        XCTAssertEqual(EchoDebug.isDebugEnabled, false)
    }
    
}
