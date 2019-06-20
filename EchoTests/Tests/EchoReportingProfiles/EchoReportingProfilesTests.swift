//
//  Copyright © 2019 BBC. All rights reserved.
//

import XCTest

import Echo

/*
 These are the values that are needed for the different apps as requested by
 Stephen.Macleod@bbc.com

 Stakeholders:
 neil.mcalpine@bbc.co.uk, John.Horth@bbc.com, Priscilla.Paula@bbc.com, jo.mitchell@bbc.co.uk

 Note: once this is merged in you can probably delete this whole comment, but it felt like it was needed somewhere in order for code review to validate this.

 Echo (defaults)
 C2 PS:16060501
 C2 WS: 19999701
 C2 GNL: 19293874
 Secret PS: 6b2a1dae06c679702e102b0f2741f180
 Secret WS: 085222b155b5c20527c344f1c7865a34
 Secret GNL: 4eac6aff7428794e427e9558d0ab6fe1

 Android Override
 20982512
 20982512
 20982512
 bd2a8394361ee741c8f79a2bbb532a06
 No override
 bd2a8394361ee741c8f79a2bbb532a06

 iOS Override
 20982512
 20982512
 20982512
 bd2a8394361ee741c8f79a2bbb532a06
 bd2a8394361ee741c8f79a2bbb532a06
 bd2a8394361ee741c8f79a2bbb532a06

 From ComScore Doc
 20982512
 19999701
 20982512
 bd2a8394361ee741c8f79a2bbb532a06
 085222b155b5c20527c344f1c7865a34
 bd2a8394361ee741c8f79a2bbb532a06
*/

class EchoReportingProfilesTests: XCTestCase {

    // Public Service (AKA News Public Service)

    func testPublicServiceConfigExists() {
        // GIVEN
        let profileForConfig = EchoProfile.PublicService

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertFalse(config.isEmpty)
    }

    func testPublicServiceConfigHasCorrectCustomerIDKey() {
        // GIVEN
        let profileForConfig = EchoProfile.PublicService

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertEqual(config[.comScoreCustomerIDKey], "20982512")
    }

    func testPublicServiceConfigHasCorrectPublisherSecret() {
        // GIVEN
        let profileForConfig = EchoProfile.PublicService

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertEqual(config[.comScorePublisherSecret], "bd2a8394361ee741c8f79a2bbb532a06")
    }

    // World Service (AKA World Service News)

    func testWorldServiceConfigExists() {
        // GIVEN
        let profileForConfig = EchoProfile.WorldService

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertFalse(config.isEmpty)
    }

    func testWorldServiceConfigHasCorrectCustomerIDKey() {
        // GIVEN
        let profileForConfig = EchoProfile.WorldService

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertEqual(config[.comScoreCustomerIDKey], "20982512")
    }

    func testWorldServiceConfigHasCorrectPublisherSecret() {
        // GIVEN
        let profileForConfig = EchoProfile.WorldService

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertEqual(config[.comScorePublisherSecret], "bd2a8394361ee741c8f79a2bbb532a06")
    }

    // GNL (AKA GNL News)

    func testGNLConfigExists() {
        // GIVEN
        let profileForConfig = EchoProfile.GNL

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertFalse(config.isEmpty)
    }

    func testGNLConfigHasCorrectCustomerIDKey() {
        // GIVEN
        let profileForConfig = EchoProfile.GNL

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertEqual(config[.comScoreCustomerIDKey], "20982512")
    }

    func testGNLConfigHasCorrectPublisherSecret() {
        // GIVEN
        let profileForConfig = EchoProfile.GNL

        // WHEN
        let config = EchoReportingProfiles.getConfigForProfile(profileForConfig)

        // THEN
        XCTAssertEqual(config[.comScorePublisherSecret], "bd2a8394361ee741c8f79a2bbb532a06")
    }
}
