//
// Created by Adam Price on 26/01/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import ComScore
import Cuckoo
import Hamcrest

@testable import Echo

class ComScoreDelegateTests: XCTestCase {

    var delegate: ComScoreDelegate!
    var appTagMock: MockComScoreAppTag!
    var streamSenseMock: MockComScoreStreamSense!
    var echoDeviceMock: MockEchoDevice!
    var cookieManagerMock: MockWebviewCookieManager!

    let appName = "App Name"
    let startCounterName = "test.start.page"
    let testLibName = "echo-ios-swift-test"
    let testLibVersion = "1.0.0"

    let validVersionID = "aValidVersionID"
    let validServiceID = "aValidServiceID"
    let validEpisodeID = "aValidEpisodeID"
    let validClipID = "aValidClipID"
    let validVPID = "aValidVPID"
    let validNonPipsContentID = "aValidNonPipsContentID"

    let unverifiedVPID = "unverified_aValidVPID"
    let unverifiedVersionID = "unverified_aValidVersionID"

    let labelsIn = ["label.a": "value.a", "label.b": "value.b"]

    var mediaOnDemandVideoEpisode: Media!
    var mediaOnDemandAudioEpisode: Media!
    var mediaOnDemandClipOnSchedule: Media!
    var mediaLiveVideoClipOffSchedule: Media!
    var mediaLiveEpisode: Media!

    var config = ComScoreDelegate.getDefaultConfig()

    var labelsCaptor = ArgumentCaptor<[String: String]>()

    var userPromiseHelper: UserPromiseHelper!
    var userPromiseHelperMock: MockUserPromiseMock!
    var webviewCookieManager: MockWebviewCookieManager!

    let LoggedInPersonalisationOn = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
    let LoggedInPersonalisationOff = BBCUser(signedIn: true)
    let LoggedInExpiredToken = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date(timeIntervalSince1970: 1))
    let LoggedInNoTimestamp = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: nil)
    let LoggedOut = BBCUser()

    let userPromiseHelperResult = UserPromiseHelperResult()

    override func setUp() {
        super.setUp()

        DefaultValueRegistry.register(value: "", forType: String?.self)
        DefaultValueRegistry.register(value: SCORStreamingState.idle, forType: SCORStreamingState.self)
        DefaultValueRegistry.register(value: LoggedOut, forType: BBCUser.self)
        DefaultValueRegistry.register(value: userPromiseHelperResult, forType: UserPromiseHelperResult.self)
        DefaultValueRegistry.register(value: UserDefaults(), forType: UserDefaults.self)

        appTagMock = MockComScoreAppTag().withEnabledSuperclassSpy()
        streamSenseMock = MockComScoreStreamSense().withEnabledSuperclassSpy()
        echoDeviceMock = MockEchoDevice().withEnabledSuperclassSpy()
        cookieManagerMock = MockWebviewCookieManager().withEnabledSuperclassSpy()
        userPromiseHelperMock = MockUserPromiseMock().withEnabledSuperclassSpy()


        userPromiseHelper = UserPromiseHelper(device: echoDeviceMock,
                                              webviewCookiesEnabled: false)

        config[.echoEnabled] = "true"
        config[.echoAutoStart] = "true"
        config[.echoCacheMode] = EchoCacheMode.all.name()
        config[.measurementLibName] = testLibName
        config[.measurementLibVersion] = testLibVersion

        mediaOnDemandVideoEpisode = Media(avType: .video, consumptionMode: .onDemand)
        mediaOnDemandVideoEpisode.versionID = "ODvidEp456"
        mediaOnDemandVideoEpisode.episodeID = "Episode34"

        mediaOnDemandAudioEpisode = Media(avType: .audio, consumptionMode: .onDemand)
        mediaOnDemandAudioEpisode.versionID = "ODuadClip888"
        mediaOnDemandAudioEpisode.episodeID = "radio_one"

        mediaOnDemandClipOnSchedule = Media(avType: .video, consumptionMode: .onDemand)
        mediaOnDemandClipOnSchedule.versionID = "ODvidClip123"

        mediaLiveVideoClipOffSchedule = Media(avType: .video, consumptionMode: .live)
        mediaLiveVideoClipOffSchedule.clipID = "LiveVidClip789"
        mediaLiveVideoClipOffSchedule.versionID = "Version421"
        mediaLiveVideoClipOffSchedule.serviceID = "bbc_one"

        mediaLiveEpisode = Media(avType: .video, consumptionMode: .live)
        mediaLiveEpisode.versionID = "LiveVidEp555"
        mediaLiveEpisode.serviceID = "bbc_one"

        stub(echoDeviceMock) { stub in
            when(stub.getOrientation()).thenReturn("landscape")
            when(stub.isScreenReaderEnabled()).thenReturn(true)
        }

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                device: echoDeviceMock, config: config, bbcUser: BBCUser())

        delegate.start()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func getAssetSetOnComScore() -> [String: String] {
        let captor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: captor.capture())
        return captor.value!
    }

    func getPlaylistSetOnComScore() -> [String: String] {
        let captor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).createPlaybackSession(withLabels: captor.capture())
        return captor.value!
    }

    func testShouldSendCorrectLabelsWithMultipleIDs() {

        let media = Media(avType: .video, consumptionMode: .download)
        media.versionID = validVersionID
        media.serviceID = validServiceID
        media.episodeID = validEpisodeID
        media.clipID = validClipID
        media.vpID = validVPID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validVersionID))

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVersionID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaVersionID.rawValue, validVersionID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaEpisodeID.rawValue, validEpisodeID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaClipID.rawValue, validClipID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaServiceID.rawValue, validServiceID))
    }

    func testShouldReportMediaPIDAsServiceIdWhenOnlyServiceIdSetWhenDownload() {
        let media = Media(avType: .video, consumptionMode: .download)
        media.serviceID = validServiceID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.AmbiguousID.rawValue, "1"))
    }

    func testShouldReportMediaPIDAsServiceIdWhenOnlyServiceIdSetWhenOnDemand() {
        let media = Media(avType: .video, consumptionMode: .onDemand)
        media.serviceID = validServiceID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.AmbiguousID.rawValue, "1"))
    }

    func testShouldReportMediaPIDAsVpIdWhenOnlyServiceIdAndVpIdSetWhenDownload() {
        let media = Media(avType: .video, consumptionMode: .download)

        media.vpID = validVPID
        media.serviceID = validServiceID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validVPID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVPID))
        assertThat(clip, hasEntry(EchoLabelKeys.AmbiguousID.rawValue, "1"))
    }

    func testShouldReportMediaPIDAsVpIdWhenOnlyServiceIdAndVpIdSetWhenOnDemand() {
        let media = Media(avType: .video, consumptionMode: .onDemand)

        media.vpID = validVPID
        media.serviceID = validServiceID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validVPID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVPID))
        assertThat(clip, hasEntry(EchoLabelKeys.AmbiguousID.rawValue, "1"))
    }

    func testShouldReportMediaPIDAsMostGranularWhenLive() {
        let media = Media(avType: .video, consumptionMode: .live)
        media.versionID = validVersionID
        media.episodeID = validEpisodeID
        media.clipID = validClipID
        media.isEnrichedWithESSData = true

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validVersionID))

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVersionID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaVersionID.rawValue, validVersionID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaEpisodeID.rawValue, validEpisodeID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaClipID.rawValue, validClipID))

        assertThat(clip, not(hasKey(EchoLabelKeys.AmbiguousID.rawValue)))
    }

    func testShouldReportMediaPIDAsMostGranularNotAmbiguousWhenLiveAndServiceIdSet() {
        let media = Media(avType: .video, consumptionMode: .live)

        media.versionID = validVersionID
        media.episodeID = validEpisodeID
        media.clipID = validClipID
        media.serviceID = validServiceID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validServiceID))

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaVersionID.rawValue, validVersionID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaEpisodeID.rawValue, validEpisodeID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaClipID.rawValue, validClipID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaServiceID.rawValue, validServiceID))

        assertThat(clip, not(hasKey(EchoLabelKeys.AmbiguousID.rawValue)))
    }

    func testShouldReportServiceIdWhenLiveAndSet() {
        let media = Media(avType: .video, consumptionMode: .live)

        media.serviceID = validServiceID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))
        assertThat(clip, not(hasKey(EchoLabelKeys.AmbiguousID.rawValue)))
    }

    func testShouldReportServiceIdWhenServiceIdAndVpIdSetAndLive() {
        let media = Media(avType: .video, consumptionMode: .live)

        media.serviceID = validServiceID
        media.vpID = validVPID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validServiceID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))
        assertThat(clip, not(hasKey(EchoLabelKeys.AmbiguousID.rawValue)))
    }

    func testShouldReportServiceIdWhenOnlyVpIdSetAndLive() {
        let media = Media(avType: .video, consumptionMode: .live)

        media.vpID = validVPID

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, validVPID))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, unverifiedVPID))
        assertThat(clip, hasEntry(EchoLabelKeys.AmbiguousID.rawValue, "1"))
    }

    func testShouldBeAmbiguousWhenNoIdsSet() {
        let media = Media(avType: .video, consumptionMode: .live)

        delegate.setMedia(media)

        let playlist = getPlaylistSetOnComScore()
        let clip = getAssetSetOnComScore()

        let invalid = delegate.invalidDataValue

        assertThat(playlist, hasEntry(EchoLabelKeys.PlaylistName.rawValue, invalid))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, invalid))
        assertThat(clip, hasEntry(EchoLabelKeys.AmbiguousID.rawValue, "1"))
    }

    func testGetMostPrecedentIDReturnsServiceIDWhenLiveAndValid() {
        let media = Media(avType: .video, consumptionMode: .live)

        media.serviceID = "some invalid value"
        media.versionID = validVersionID

        delegate.setMedia(media)

        var clip = getAssetSetOnComScore()

        assertThat(clip, not(hasEntry(EchoLabelKeys.MediaPID.rawValue, "some invalid value")))

        media.serviceID = validServiceID

        delegate.setMedia(media)

        clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))

        media.consumptionMode = .download

        delegate.setMedia(media)

        clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVersionID))
    }

    func testGetMostPrecedentIDReturnsVersionIDWhenValid() {
        let media = Media(avType: .video, consumptionMode: .download)

        media.serviceID = validServiceID
        media.versionID = validVersionID

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVersionID))
    }

    func testGetMostPrecedentIdReturnsClipIdWhenValid() {
        let media = Media(avType: .video, consumptionMode: .download)

        media.serviceID = validServiceID
        media.versionID = "invalid version id"
        media.clipID = validClipID

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validClipID))
    }

    func testGetMostPrecedentIdReturnsEpisodeIdWhenValid() {
        let media = Media(avType: .video, consumptionMode: .download)

        media.serviceID = validServiceID
        media.versionID = "invalid version id"
        media.clipID = "invlid clip id"
        media.episodeID = validEpisodeID

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validEpisodeID))
    }

    func testGetMostPrecedentIdReturnsVpIdWhenValid() {
        let media = Media(avType: .video, consumptionMode: .download)

        media.serviceID = validServiceID
        media.versionID = "invalid version id"
        media.clipID = "invalid clip id"
        media.episodeID = "invalid episode id"
        media.vpID = validVPID

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validVPID))
    }

    func testGetMostPrecedentIdReturnsServiceIdWhenNotLiveAndValid() {
        let media = Media(avType: .video, consumptionMode: .download)

        media.serviceID = validServiceID
        media.versionID = "invalid version id"
        media.clipID = "invalid clip id"
        media.episodeID = "invalid episode id"
        media.vpID = "invalid vpid"

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validServiceID))
    }
    
    func testSettingNonPipsContentIdShouldSetContentId() {
        let media = Media(avType: .video, consumptionMode: .download)
        
        media.serviceID = validServiceID
        media.versionID = "invalid version id"
        media.clipID = "invalid clip id"
        media.episodeID = "invalid episode id"
        media.vpID = "invalid vpid"
        media.nonPipsContentID = validNonPipsContentID
        
        delegate.setMedia(media)
        
        let clip = getAssetSetOnComScore()
        
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validNonPipsContentID))
    }
    
    func testRemoveWhiteSpaceWhenSettingNonPipsContentIdShouldSetContentId() {
        let media = Media(avType: .video, consumptionMode: .download)
        
        media.serviceID = validServiceID
        media.versionID = "invalid version id"
        media.clipID = "invalid clip id"
        media.episodeID = "invalid episode id"
        media.vpID = "invalid vpid"
        media.nonPipsContentID = " \(validNonPipsContentID) "
        
        delegate.setMedia(media)
        
        let clip = getAssetSetOnComScore()
        
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, validNonPipsContentID))
    }

    func testMarksContentIdAsUnverifiedWhenUsingUnconfirmedVersionId() {
        let media = Media(avType: .video, consumptionMode: .live)
        media.versionID = validVersionID
        delegate.setMedia(media)
        let clip = getAssetSetOnComScore()
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, unverifiedVersionID))
    }

    func testMarksContentIDAsUnverifiedWhenUsingUnconfirmedVpID() {
        let media = Media(avType: .video, consumptionMode: .live)
        media.vpID = validVPID
        delegate.setMedia(media)
        let clip = getAssetSetOnComScore()
        assertThat(clip, hasEntry(EchoLabelKeys.MediaPID.rawValue, unverifiedVPID))
    }

    // MARK: Identify playback method / content type

    func testPlaybackContentTypeSetForDownloadedVideo() {
        let media = Media(avType: .video, consumptionMode: .download)

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaMedium.rawValue, "video"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaRetrievalType.rawValue, "download"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaLiveOrOnDemand.rawValue, "on-demand"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaStreamType.rawValue, "vod"))
    }

    func testClearMediaStopsStreamSenseTrackingIfStreamIsActive() {

        stub(streamSenseMock) { stub in
            when(stub.state.get).thenReturn(SCORStreamingState.playing).thenReturn(SCORStreamingState.idle)
        }

        delegate.setMedia(mediaOnDemandVideoEpisode)

        delegate.avPlayEvent(at: 10, eventLabels: labelsIn)

        delegate.clearMedia()

        verify(streamSenseMock).notifyEnd(withPosition: equal(to: 0), labels: any())
    }

    func testClearMediaSetsAppTagOnUxInactive() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        delegate.clearMedia()
        verify(appTagMock, atLeastOnce()).notifyUXInactive()
    }

    func testPlaybackContentTypeSetForDownloadedAudio() {
        let media = Media(avType: .audio, consumptionMode: .download)

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaMedium.rawValue, "audio"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaRetrievalType.rawValue, "download"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaLiveOrOnDemand.rawValue, "on-demand"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaStreamType.rawValue, "aod"))
    }

    func testPlaybackContentTypeSetForOnDemandVideo() {
        let media = Media(avType: .video, consumptionMode: .onDemand)

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaMedium.rawValue, "video"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaRetrievalType.rawValue, "stream"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaLiveOrOnDemand.rawValue, "on-demand"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaStreamType.rawValue, "vod"))
    }

    func testPlaybackContentTypeSetForOnDemandAudio() {
        let media = Media(avType: .audio, consumptionMode: .onDemand)

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaMedium.rawValue, "audio"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaRetrievalType.rawValue, "stream"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaLiveOrOnDemand.rawValue, "on-demand"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaStreamType.rawValue, "aod"))
    }

    func testPlaybackContentTypeSetForLiveVideo() {
        let media = Media(avType: .video, consumptionMode: .live)

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaMedium.rawValue, "video"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaRetrievalType.rawValue, "stream"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaLiveOrOnDemand.rawValue, "live"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaStreamType.rawValue, "live"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaIsLive.rawValue, "1"))
    }

    func testPlaybackContentTypeSetForLiveAudio() {
        let media = Media(avType: .audio, consumptionMode: .live)

        delegate.setMedia(media)

        let clip = getAssetSetOnComScore()

        assertThat(clip, hasEntry(EchoLabelKeys.MediaMedium.rawValue, "audio"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaRetrievalType.rawValue, "stream"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaLiveOrOnDemand.rawValue, "live"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaStreamType.rawValue, "live"))
        assertThat(clip, hasEntry(EchoLabelKeys.MediaIsLive.rawValue, "1"))
    }

    // MARK: Constructor Tests

    func testConstructorSetsSiteLabelForSCR() {
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.ScorecardDomainSite.rawValue),
                        value: equal(to: config[.comScoreSite]))
    }

    func testConstructorPassesCorrectPublisherIDForSCR() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.publisherId, equalTo("20982512"))
    }

    func testConstructorPassesCorrectSecureSettingToAppTag() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.secureTransmission, equalTo(true))
    }

    func testConstructorSetsAppName() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.applicationName, equalTo(appName))
    }

    func testConstructorSetsAppTypeLabel() {
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCApplicationType.rawValue),
                        value: equal(to: ApplicationType.mobileApp.name()))
    }

    func testConstructorSetsLiveEndpointURL() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.liveEndpointURL, equalTo("https://sb.scorecardresearch.com/p2"))
    }

    func testConstructorSetsPublisherSecret() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.publisherSecret, equalTo("bd2a8394361ee741c8f79a2bbb532a06"))
    }

    func testConstructorSetsKeepAliveToFalse() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.keepAliveMeasurement, equalTo(false))
    }

    func testConstructorSetsCacheMode() {
        assertThat(delegate.getCacheMode(), presentAnd(equalTo(EchoCacheMode.all)))
        verify(appTagMock, atLeastOnce()).liveTransmissionMode.set(equal(to: SCORLiveTransmissionModeCache))
        verify(appTagMock, atLeastOnce()).offlineCacheMode.set(equal(to: SCOROfflineCacheMode.manualFlush))
    }

    func testConstructorSetsStartCounterNameLabel() {
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCCounterName.rawValue),
                        value: equal(to: startCounterName))
    }

    func testConstructorSetsTraceLabelWhenPresent() {
        let uuid = UUID().uuidString
        config[.echoTrace] = uuid

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                startCounterName: startCounterName, appTag: appTagMock!, streamSense: streamSenseMock!,
                device: echoDeviceMock!, config: config, bbcUser: BBCUser())

        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.EchoTrace.rawValue),
                        value: equal(to: uuid))
    }

    func testConstructorHandlesAbsentTraceLabel() {
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.EchoTrace.rawValue),
                                                       value: anyString())
    }

    func testConstructorSetsMeasurementLibNameLabel() {
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.MeasurementLibName.rawValue),
                        value: equal(to: testLibName))
    }

    func testConstructorSetsMeasurementLibVersionLabel() {
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.MeasurementLibVersion.rawValue),
                        value: equal(to: testLibVersion))
    }

    // MARK: Application State Tests

    func testSetCacheModeSetsTheMode() {
        delegate.setCacheMode(.offline)
        assertThat(delegate.getCacheMode(), presentAnd(equalTo(.offline)))
        delegate.setCacheMode(.all)
        assertThat(delegate.getCacheMode(), presentAnd(equalTo(.all)))
    }

    func testSetCacheModeCallsAppTagMethodsForAll() {
        // need this first so we can test setting to 'all' (which is default for these tests)
        delegate.setCacheMode(.offline)
        reset(appTagMock)
        delegate.setCacheMode(.all)
        verify(appTagMock, atLeastOnce()).liveTransmissionMode.set(equal(to: SCORLiveTransmissionModeCache))
        verify(appTagMock, atLeastOnce()).offlineCacheMode.set(equal(to: SCOROfflineCacheMode.manualFlush))
    }

    func testSetCacheModeCallsAppTagMethodsForOffline() {
        reset(appTagMock)
        delegate.setCacheMode(.offline)
        verify(appTagMock).liveTransmissionMode.set(equal(to: SCORLiveTransmissionModeStandard))
        verify(appTagMock).offlineCacheMode.set(equal(to: SCOROfflineCacheMode.enabled))
    }

    func testFlushCacheCallsAppTag() {
        delegate.flushCache()
        verify(appTagMock).flushCache()
    }

    func testSetContentLanguageSetsLabel() {
        delegate.setContentLanguage("LANG")
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.Language.rawValue),
                        value: equal(to: "LANG"))
    }

    func testSetBBCUserSetsCorrectLabel() {
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)

        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: ""))
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                        value: equal(to: "1"))

        delegate.updateBBCUserLabels(LoggedOut)

        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: ""))
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                        value: equal(to: nil))
    }

    func testSetBBCUserWithBlankIdSetsCorrectLabel() {
        delegate.updateBBCUserLabels(LoggedInPersonalisationOff)

        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: ""))
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: "invalid-data"))
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                        value: equal(to: "1"))

        delegate.updateBBCUserLabels(LoggedOut)

        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: ""))
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: "invalid-data"))
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                        value: equal(to: nil))
    }

    func testConstructorDefaultsForManagedLabels() {
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCSite.rawValue),
                        value: equal(to: delegate.invalidDataValue))
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.EventMasterBrand.rawValue),
                        value: anyString())
        verify(streamSenseMock, never()).setLabel(withName: equal(to: EchoLabelKeys.EventMasterBrand.rawValue),
                        value: anyString())
    }

    func testConstructorDoesNotDefaultManagedLabels() {
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.EventMasterBrand.rawValue),
                        value: equal(to: delegate.invalidDataValue))
    }

    func testAddManagedLabelsPersistsLabelForAVAndNonAV() {
        delegate.addManagedLabel(.eventMasterBrand, value: "bleep")
        delegate.addManagedLabel(.bbcSite, value: "bloop")

        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.EventMasterBrand.rawValue),
                        value: equal(to: "bleep"))
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCSite.rawValue),
                        value: equal(to: "bloop"))
    }

    func testAddValidStoreManagedLabels() {
        delegate.addManagedLabel(.iPlayerState, value: "purchased")
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.iPlayerState.rawValue),
                        value: equal(to: "purchased"))
    }

    func testAddCleansedInvalidStoreManagedLabels() {
        delegate.addManagedLabel(.iPlayerState, value: "cheese")
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.iPlayerState.rawValue),
                        value: equal(to: delegate.invalidDataValue))
    }

    func testAddValidHashedIDLabel() {
        delegate.addManagedLabel(.bbcHashedID, value: "test--12_!string")
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: "test--12_!string"))
    }

    func testDontAddEmptyHashedIdLabel() {
        delegate.addManagedLabel(.bbcHashedID, value: "")
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                        value: equal(to: delegate.invalidDataValue))
    }

    func testAddLabelsCallsComScore() {
        delegate.addLabels(labelsIn)

        let captor = ArgumentCaptor<[String: String]>()

        verify(appTagMock).setPersistentLabels(captor.capture())

        assertThat(captor.value!, containsLabels(labelsIn))
    }

    func testRemoveLabelsCallsComScoreWithNilForEachKey() {
        delegate.removeLabels(["A", "B", "C"])

        verify(appTagMock).setPersistentLabel(withName: equal(to: "A"), value: equal(to: nil))
        verify(appTagMock).setPersistentLabel(withName: equal(to: "B"), value: equal(to: nil))
        verify(appTagMock).setPersistentLabel(withName: equal(to: "C"), value: equal(to: nil))
    }

    // MARK: Application Event Tests

    func testAppForegroundedCallsComScore() {
        delegate.appForegrounded()
        verify(appTagMock, atLeastOnce()).notifyEnterForeground()
    }

    func testAppBackgroundedCallsComScore() {
        delegate.appBackgrounded()
        verify(appTagMock, atLeastOnce()).notifyExitForeground()
    }

    // MARK: Basic Analytics Tests

    func testViewEventCallsComScoreWithLabels() {

        delegate.viewEvent(counterName: "news.page", eventLabels: labelsIn)

        verify(appTagMock).notifyViewEvent(withLabels: labelsCaptor.capture())

        // Check for user supplied labels
        assertThat(labelsCaptor.value!, containsLabels(labelsIn))

        // Check for Echo event label
        assertThat(labelsCaptor.value!, containsLabels([EchoLabelKeys.EchoEventName.rawValue: "view"]))

        // Check for counter name
        assertThat(labelsCaptor.value!, containsLabels([EchoLabelKeys.BBCCounterName.rawValue: "news.page"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock, times(2)).setPersistentLabels(captor.capture())

        // Check that counter name is added to persistent labels
        assertThat(captor.allValues[1], containsLabels([EchoLabelKeys.BBCCounterName.rawValue: "news.page"]))

        // Check persistent label values are added
        assertThat(captor.allValues[0],
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testUserActionEventCallsComScoreWithLabels() {
        delegate.userActionEvent(actionType: "aType", actionName: "aName", eventLabels: labelsIn)

        verify(appTagMock).notifyHiddenEvent(withLabels: labelsCaptor.capture())

        // Check for user supplied labels
        assertThat(labelsCaptor.value!, containsLabels(labelsIn))

        // Check for Echo event label
        assertThat(labelsCaptor.value!, containsLabels([EchoLabelKeys.EchoEventName.rawValue: "userAct"]))

        // Check specific labels for this event have been added
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.UserActionType.rawValue: "aType",
                                EchoLabelKeys.UserActionName.rawValue: "aName"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.value!,
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testErrorEventNotDelegated() {
        reset(appTagMock)
        reset(streamSenseMock)
        delegate.errorEvent("Snap!!", eventLabels: labelsIn)
        verifyNoMoreInteractions(appTagMock)
        verifyNoMoreInteractions(streamSenseMock)
    }

    // MARK: Media Player Tests

    func testSetPlayerNameCallsComScore() {
        delegate.setPlayerName("playerName")

        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.PlayerName.rawValue),
                        value: equal(to: "playerName"))
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerName.rawValue),
                        value: equal(to: "playerName"))
    }

    func testSetPlayerVersionCallsComScore() {
        delegate.setPlayerVersion("playerVersion")

        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.PlayerVersion.rawValue),
                        value: equal(to: "playerVersion"))
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerVersion.rawValue),
                        value: equal(to: "playerVersion"))
    }

    func testSetPlayerIsPoppedCallsComScore() {
        delegate.setPlayerIsPopped(true)
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerPopped.rawValue),
                        value: equal(to: "1"))
        delegate.setPlayerIsPopped(false)
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerPopped.rawValue),
                        value: equal(to: "0"))
    }

    func testSetPlayerWindowStateCallsComScore() {
        delegate.setPlayerWindowState(.resized)
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerWindowState.rawValue),
                        value: equal(to: WindowState.resized.getCSValue()))
    }

    func testSetPlayerVolumeCallsComScore() {
        delegate.setPlayerVolume(50)
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerVolume.rawValue),
                        value: equal(to: "50"))
    }

    func testSetPlayerIsSubtitledCallsComScore() {
        delegate.setPlayerIsSubtitled(true)
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerSubtitled.rawValue),
                        value: equal(to: "1"))
        delegate.setPlayerIsSubtitled(false)
        verify(streamSenseMock).setLabel(withName: equal(to: EchoLabelKeys.PlayerSubtitled.rawValue),
                        value: equal(to: "0"))
    }

    // MARK: Media Metadata Tests

    func testComScoreNameLabelIsSetOnPlaylist() {
        delegate.setMedia(mediaOnDemandClipOnSchedule!)
        assertThat(getPlaylistSetOnComScore(),
                containsLabels([EchoLabelKeys.PlaylistName.rawValue: mediaOnDemandClipOnSchedule!.versionID]))
    }

    func testComScoreMediaIdLabelIsSetOnClip() {
        delegate.setMedia(mediaOnDemandClipOnSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaVersionID.rawValue: mediaOnDemandClipOnSchedule!.versionID]))
    }

    func testBBCClipIdLabelIsSetOnClipForPipsClip() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaClipID.rawValue: mediaLiveVideoClipOffSchedule!.clipID]))
    }

    func testBBCEpisodeIdLabelIsNotSetOnClipForPipsClip() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(), not(hasKey(EchoLabelKeys.MediaEpisodeID.rawValue)))
    }

    func testBBCClipIdLabelIsNotSetForPipsEpisodeOnClip() {
        delegate.setMedia(mediaLiveEpisode!)
        assertThat(getAssetSetOnComScore(), not(hasKey(EchoLabelKeys.MediaClipID.rawValue)))
    }

    func testBBCEpisodeIdLabelIsSetForPipsEpisodeOnClip() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaEpisodeID.rawValue: mediaOnDemandVideoEpisode!.episodeID]))
    }

    func testBBCVersionIdLabelIsSetOnClip() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaVersionID.rawValue: mediaLiveVideoClipOffSchedule!.versionID]))
    }

    func testComScoreClipNumberLabelIsSetOnClip() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaClipNumber.rawValue: "1"]))
    }

    func testComScorePartNumberLabelIsSetOnClip() {
        delegate.setMedia(mediaLiveEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaPartNumber.rawValue: "1"]))
    }

    func testComScoreTotalPartsLabelIsSetOnClip() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaTotalParts.rawValue: "1"]))
    }

    func testComScoreMediaLengthLabelIsSetOnClip() {
        mediaOnDemandVideoEpisode!.length = 1680000
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaLength.rawValue: "1680000"]))
    }

    func testComScoreStreamTypeLabelIsSetCorrectlyOnClipForLiveStream() {
        delegate.setMedia(mediaLiveEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaStreamType.rawValue: "live"]))
    }

    func testBBCServiceIdLabelIsSetOnClipForLiveStreamIfPresent() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaServiceID.rawValue:
                                mediaLiveVideoClipOffSchedule!.serviceID]))
    }

    func testComScoreLiveFlagLabelIsSetOnClipForLiveStream() {
        delegate.setMedia(mediaLiveEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaIsLive.rawValue: "1"]))
    }

    func testBBCLiveOnDemandLabelSetCorrectlyOnClipForLiveStream() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaLiveOrOnDemand.rawValue: "live"]))
    }

    func testComScoreStreamTypeLabelIsSetCorrectlyOnClipForOnDemandVideo() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaStreamType.rawValue: "vod"]))
    }

    func testComScoreStreamTypeLabelIsSetCorrectlyOnClipForOnDemandAudio() {
        delegate.setMedia(mediaOnDemandAudioEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaStreamType.rawValue: "aod"]))
    }

    func testBBCLiveOnDemandLabelSetCorrectlyOnClipForOnDemandStream() {
        delegate.setMedia(mediaOnDemandAudioEpisode!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaLiveOrOnDemand.rawValue: "on-demand"]))
    }

    func testBBCMediumLabelIsSetCorrectlyOnClip() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaMedium.rawValue:
                                mediaLiveVideoClipOffSchedule!.avType.name()]))
    }

    func testBBCRetrievalTypeLabelIsSetCorrectlyOnClip() {
        delegate.setMedia(mediaLiveVideoClipOffSchedule!)
        assertThat(getAssetSetOnComScore(),
                containsLabels([EchoLabelKeys.MediaRetrievalType.rawValue:
                                mediaLiveVideoClipOffSchedule!.retrievalType.name()]))
    }

    func testShouldSetComScorePublisherSpecificUniqueIDToTheDeviceID() {
        config[.idv5Enabled] = "true"
        config[.echoAutoStart] = "false"



        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                device: echoDeviceMock, config: config, bbcUser: BBCUser())

        stub(echoDeviceMock) { stub in
            when(stub.getDeviceID()).thenReturn("some-device-id")
        }

        delegate.updateDeviceID(echoDeviceMock.getDeviceID())
        verify(appTagMock).publisherSpecificUniqueID.set(equal(to: "some-device-id"))
    }

    func testSetMediaLengthCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        delegate.setMediaLength(50000)

        verify(streamSenseMock).setAssetLabel(withName: equal(to: EchoLabelKeys.MediaLength.rawValue),
                                              value: equal(to: "50000"))
    }

    // MARK: Media Event Tests

    func testAVPlayCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        delegate.avPlayEvent(at: 10, eventLabels: labelsIn)

        verify(streamSenseMock).notifyPlay(withPosition: equal(to: 10), labels: labelsCaptor.capture())

        verify(appTagMock).notifyUXActive()

        // User labels should be forwarded
        assertThat(labelsCaptor.value!, containsLabels(labelsIn))

        // Check specific labels for this event have been added
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avPlay"]))
    }

    func testAVPlaySetsCorrectPlayheadPositionForDownload() {
        delegate.setMedia(Media(avType: .video, consumptionMode: .download))
        delegate.avPlayEvent(at: 123, eventLabels: labelsIn)

        verify(streamSenseMock).notifyPlay(withPosition: equal(to: 123), labels: labelsCaptor.capture())

        verify(appTagMock).notifyUXActive()

        // User labels should be forwarded
        assertThat(labelsCaptor.value!, containsLabels(labelsIn))

        // Check specific labels for this event have been added
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avPlay"]))
    }

    func testAVBufferCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avBufferEvent(at: 15, eventLabels: labelsIn)

        verify(streamSenseMock).notifyBufferStart(withPosition: equal(to: 15), labels: labelsCaptor.capture())

        verify(appTagMock, atLeastOnce()).notifyUXInactive()

        // User labels should be forwarded
        assertThat(labelsCaptor.value!, containsLabels(labelsIn))

        // Check specific labels for this event have been added
        assertThat(labelsCaptor.value!,
                   containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avBuffer"]))
    }

    func testAVPauseCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avPauseEvent(at: 15, eventLabels: labelsIn)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 15), labels: labelsCaptor.capture())

        verify(appTagMock, atLeastOnce()).notifyUXInactive()

        // User labels should be forwarded
        assertThat(labelsCaptor.value!, containsLabels(labelsIn))

        // Check specific labels for this event have been added
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avPause"]))
    }

    func testAVEndEventCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avEndEvent(at: 70, eventLabels: labelsIn)

        verify(streamSenseMock).notifyEnd(withPosition: equal(to: 70), labels: labelsCaptor.capture())

        verify(appTagMock).notifyUXInactive()

        assertThat(labelsCaptor.value!, containsLabels(labelsIn))
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avEnd",
                                EchoLabelKeys.PlaylistEnd.rawValue: "1"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.value!,
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testAVRewindEventCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avRewindEvent(at: 300, rate: 3, eventLabels: labelsIn)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 300), labels: labelsCaptor.capture())

        verify(appTagMock, atLeastOnce()).notifyUXInactive()

        assertThat(labelsCaptor.value!, containsLabels(labelsIn))
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avRW",
                                EchoLabelKeys.EventTriggeredByUser.rawValue: "rewind",
                                EchoLabelKeys.RewindFFRate.rawValue: "3"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.value!,
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testAVFastForwardEventCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avFastForwardEvent(at: 400, rate: 2, eventLabels: labelsIn)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 400), labels: labelsCaptor.capture())

        verify(appTagMock, atLeastOnce()).notifyUXInactive()

        assertThat(labelsCaptor.value!, containsLabels(labelsIn))
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avFF",
                                EchoLabelKeys.EventTriggeredByUser.rawValue: "fastforward",
                                EchoLabelKeys.RewindFFRate.rawValue: "2"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.value!,
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testAVSeekCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode!)
        delegate.avSeekEvent(at: 1000, eventLabels: labelsIn)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 1000), labels: labelsCaptor.capture())

        verify(appTagMock, atLeastOnce()).notifyUXInactive()

        assertThat(labelsCaptor.value!, containsLabels(labelsIn))
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avSeek",
                                EchoLabelKeys.EventTriggeredByUser.rawValue: "seek"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.value!,
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testAVUserActionCallsComScore() {
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avUserActionEvent(actionType: "aType", actionName: "aName", position: 800, eventLabels: labelsIn)

        verify(streamSenseMock).notifyCustomEvent(withPosition: equal(to: 800), labels: labelsCaptor.capture())

        assertThat(labelsCaptor.value!, containsLabels(labelsIn))
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EchoEventName.rawValue: "avUserAct",
                                EchoLabelKeys.StreamSenseCustomEventType.rawValue: "aType",
                                EchoLabelKeys.UserActionType.rawValue: "aType",
                                EchoLabelKeys.UserActionName.rawValue: "aName"]))

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.value!,
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    // MARK: Helper and Static Methods Tests

    func testDefaultConfigUsesHttpsEndpoint() {
        let captor = ArgumentCaptor<SCORPublisherConfiguration>()
        verify(appTagMock, atLeastOnce()).addClient(withConfiguration: captor.capture())
        assertThat(captor.value!.liveEndpointURL, hasPrefix("https"))
    }

    // MARK: Standard Label Methods Tests

    func testOrientationPortraitMapsCorrectly() {
        stub(echoDeviceMock) { stub in
            when(stub.getOrientation()).thenReturn("portrait")
        }

        delegate.viewEvent(counterName: "some.page", eventLabels: nil)

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock, times(2)).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.allValues[0],
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "portrait",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testOrientationLandscapeMapsCorrectly() {
        stub(echoDeviceMock) { stub in
            when(stub.getOrientation()).thenReturn("landscape")
        }

        delegate.viewEvent(counterName: "some.page", eventLabels: nil)

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock, times(2)).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.allValues[0],
                containsLabels([EchoLabelKeys.BBCUIOrientation.rawValue: "landscape",
                                EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testScreenreaderEnabledMapsCorrectly() {
        stub(echoDeviceMock) { stub in
            when(stub.isScreenReaderEnabled()).thenReturn(true)
        }

        delegate.viewEvent(counterName: "some.page", eventLabels: nil)

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock, times(2)).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.allValues[0],
                containsLabels([EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "true"]))
    }

    func testScreenreaderDisabledMapsCorrectly() {
        stub(echoDeviceMock) { stub in
            when(stub.isScreenReaderEnabled()).thenReturn(false)
        }

        delegate.viewEvent(counterName: "some.page", eventLabels: nil)

        let captor = ArgumentCaptor<[String: String]>()
        verify(appTagMock, times(2)).setPersistentLabels(captor.capture())

        // Check persistent label values are added
        assertThat(captor.allValues[0],
                containsLabels([EchoLabelKeys.BBCScreenReaderEnabled.rawValue: "false"]))
    }

    // MARK: Live Streaming Tests

    func testLiveMediaUpdateEndsAndPlaysWhenPositionSpecified() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.liveMediaUpdate(mediaLiveEpisode!, newPosition: 200, oldPosition: 100)

        verify(streamSenseMock).notifyEnd(withPosition: equal(to: 100), labels: labelsCaptor.capture())
        verify(streamSenseMock).notifyPlay(withPosition: equal(to: 200), labels: labelsCaptor.capture())
    }

    func testSetMediaLengthUpdatesClipLength() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.setMediaLength(1000)

        verify(streamSenseMock).setAssetLabel(withName: equal(to: EchoLabelKeys.MediaLength.rawValue),
                                              value: equal(to: "1000"))
    }

    func testLiveMediaUpdateIncrementsClipNumber() {
        let media1 = Media(avType: .video, consumptionMode: .live)
        media1.versionID = "version1"
        let media2 = Media(avType: .video, consumptionMode: .live)
        media2.versionID = "version1"

        delegate.liveMediaUpdate(media1, newPosition: 100, oldPosition: 200)

        let clipCaptor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: clipCaptor.capture())

        assertThat(clipCaptor.value!,
                containsLabels([EchoLabelKeys.MediaClipNumber.rawValue: "1"]))

        delegate.liveMediaUpdate(media1, newPosition: 200, oldPosition: 300)

        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: clipCaptor.capture())

        assertThat(clipCaptor.value!,
                containsLabels([EchoLabelKeys.MediaClipNumber.rawValue: "2"]))
    }

    func testLiveMediaUpdateDoesNotSetTheComscoreLiveLabelWhenEnriched() {
        mediaLiveEpisode.isEnrichedWithESSData = true
        delegate.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)

        let clipCaptor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: clipCaptor.capture())

        assertThat(clipCaptor.value!, not(hasKey(EchoLabelKeys.MediaIsLive.rawValue)))
    }

    func testLiveMediaUpdateSetsTheComscoreLiveLabelToOneWhenNotEnriched() {
        mediaLiveEpisode.isEnrichedWithESSData = false
        delegate.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)

        let clipCaptor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: clipCaptor.capture())

        assertThat(clipCaptor.value!,
                containsLabels([EchoLabelKeys.MediaIsLive.rawValue: "1"]))
    }

    func testLiveMediaUpdateSetsEssEnrichedLabelToTrueWhenEnriched() {
        mediaLiveEpisode.isEnrichedWithESSData = true
        delegate.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)

        let clipCaptor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: clipCaptor.capture())

        assertThat(clipCaptor.value!,
                containsLabels([EchoLabelKeys.ESSEnriched.rawValue: "true"]))
    }

    func testLiveMediaUpdateSetsEssEnrichedLabelToFalseWhenNotEnriched() {
        mediaLiveEpisode.isEnrichedWithESSData = false
        delegate.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)

        let clipCaptor = ArgumentCaptor<[String: String]>()
        verify(streamSenseMock, atLeastOnce()).setAsset(withLabels: clipCaptor.capture())

        assertThat(clipCaptor.value!,
                containsLabels([EchoLabelKeys.ESSEnriched.rawValue: "false"]))
    }

    func testLiveMediaUpdateEndsTheCurrentClipWithoutEndingPlaylist() {
        delegate.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)
        verify(streamSenseMock).notifyEnd(withPosition: equal(to: 200), labels: labelsCaptor.capture())
    }

    func testLiveMediaUpdatePlaysClipWithNewPosition() {
        delegate.liveMediaUpdate(mediaLiveEpisode, newPosition: 100, oldPosition: 200)
        verify(streamSenseMock).notifyPlay(withPosition: equal(to: 100), labels: labelsCaptor.capture())
    }

    func testAVPlayReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avPlayEvent(at: 200, eventLabels: nil)
        verify(streamSenseMock).notifyPlay(withPosition: equal(to: 0), labels: labelsCaptor.capture())
    }

    func testAVPauseReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avPauseEvent(at: 200, eventLabels: nil)
        verify(streamSenseMock).notifyPause(withPosition: equal(to: 0), labels: labelsCaptor.capture())
    }

    func testAVBufferReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avBufferEvent(at: 200, eventLabels: nil)
        verify(streamSenseMock).notifyBufferStart(withPosition: equal(to: 0), labels: labelsCaptor.capture())
    }

    func testAVEndReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avEndEvent(at: 200, eventLabels: nil)
        verify(streamSenseMock).notifyEnd(withPosition: equal(to: 0), labels: labelsCaptor.capture())
    }

    func testAVFastForwardReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avFastForwardEvent(at: 200, rate: 2, eventLabels: nil)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 0), labels: labelsCaptor.capture())

        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EventTriggeredByUser.rawValue: "fastforward",
                                EchoLabelKeys.RewindFFRate.rawValue: "2"]))
    }

    func testAVRewindReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avRewindEvent(at: 200, rate: 2, eventLabels: nil)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 0), labels: labelsCaptor.capture())
        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EventTriggeredByUser.rawValue: "rewind",
                                EchoLabelKeys.RewindFFRate.rawValue: "2"]))
    }

    func testAVSeekReportsPostionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avSeekEvent(at: 200, eventLabels: nil)

        verify(streamSenseMock).notifyPause(withPosition: equal(to: 0), labels: labelsCaptor.capture())

        assertThat(labelsCaptor.value!,
                containsLabels([EchoLabelKeys.EventTriggeredByUser.rawValue: "seek"]))
    }

    func testAVUserActionReportsPositionAsZeroIfFirstClipInLiveStream() {
        delegate.setMedia(mediaLiveEpisode)
        delegate.avUserActionEvent(actionType: "type", actionName: "name", position: 200, eventLabels: nil)
        verify(streamSenseMock).notifyCustomEvent(withPosition: equal(to: 0), labels: labelsCaptor.capture())
    }

    func testClearMediaEmptiesClipsArray() {
        let clip: [String: String] = [:]
        delegate.assets.append(clip)
        delegate.clearMedia()
        assertThat(delegate.assets.count, equalTo(0))
    }

    func testClipNumberReturnsCorrectNumber() {
        var clip: [String: String] = [:]
        clip[EchoLabelKeys.MediaPID.rawValue] = "bbc_one_wales"
        var clip2: [String: String] = [:]
        clip2[EchoLabelKeys.MediaPID.rawValue] = "b038nzy4"
        var clip3: [String: String] = [:]
        clip3[EchoLabelKeys.MediaPID.rawValue] = "p03hd49z"

        delegate.assets.append(clip)
        delegate.assets.append(clip2)
        delegate.assets.append(clip3)

        var clipNumber = delegate.getAssetNumber("b038nzy4")
        assertThat(clipNumber, equalTo(2))

        clipNumber = delegate.getAssetNumber("bbc_one_wales")
        assertThat(clipNumber, equalTo(1))

        clipNumber = delegate.getAssetNumber("previously_unused_id")
        assertThat(clipNumber, equalTo(4))
    }

    func testGetStreamSenseClipCreatesNewClipIfNewClipNumber() {
        var clip: [String: String] = [:]
        clip[EchoLabelKeys.MediaPID.rawValue] = "bbc_one_wales"
        clip[EchoLabelKeys.MediaClipNumber.rawValue] = "1"
        var clip2: [String: String] = [:]
        clip2[EchoLabelKeys.MediaPID.rawValue] = "b038nzy4"
        clip2[EchoLabelKeys.MediaClipNumber.rawValue] = "2"
        var clip3: [String: String] = [:]
        clip3[EchoLabelKeys.MediaPID.rawValue] = "p03hd49z"
        clip3[EchoLabelKeys.MediaClipNumber.rawValue] = "3"

        delegate.assets.append(clip)
        delegate.assets.append(clip2)
        delegate.assets.append(clip3)

        let media = Media(avType: .video, consumptionMode: .live)
        media.isEnrichedWithESSData = true
        media.versionID = "new_id"

        _ = delegate.getStreamSenseAsset(media)

        assertThat(delegate.assets.count, equalTo(4))
        assertThat(delegate.assets[3],
                containsLabels([EchoLabelKeys.MediaPID.rawValue: "new_id"]))
    }

    func testGetStreamSenseClipReusesExistingClipIfReusingClipNumber() {
        var clip: [String: String] = [:]
        clip[EchoLabelKeys.MediaPID.rawValue] = "bbc_one_wales"
        clip[EchoLabelKeys.MediaClipNumber.rawValue] = "1"
        var clip2: [String: String] = [:]
        clip2[EchoLabelKeys.MediaPID.rawValue] = "b038nzy4"
        clip2[EchoLabelKeys.MediaClipNumber.rawValue] = "2"
        var clip3: [String: String] = [:]
        clip3[EchoLabelKeys.MediaPID.rawValue] = "p03hd49z"
        clip3[EchoLabelKeys.MediaClipNumber.rawValue] = "3"

        delegate.assets.append(clip)
        delegate.assets.append(clip2)
        delegate.assets.append(clip3)

        let media = Media(avType: .video, consumptionMode: .live)
        media.versionID = "b038nzy4"

        let retrievedClip = delegate.getStreamSenseAsset(media)

        assertThat(delegate.assets.count, equalTo(3))
        assertThat(delegate.assets[1], containsLabels(retrievedClip))
    }

    // MARK: Device ID Generation Event Tests

    // TODO: these tests are deterministic - they will pass once but not on subsequent attempts
    // I'm not sure how to get around this yet (clearing stored data doesn't do it)

//    func testCustomEventSentWhenDeviceIdGeneratedAfterNewInstall() {
//        stub(echoDeviceMock) { stub in when(stub.isNewInstall.get).thenReturn(true) }
//
//        config[.idv5Enabled] = "true"
//
//        userPromiseHelper.clearStoredUserData()
//
//        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
//                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
//                                    device: echoDeviceMock, config: config, bbcUser: BBCUser(),
//                                    userPromiseHelper: userPromiseHelper
//        )
//
//        verify(appTagMock).notifyHiddenEvent(withLabels: labelsCaptor.capture())
//        assertThat(labelsCaptor.value!, containsLabels(["action_type": "echo_device_id",
//                                                        "action_name": "first_install",
//                                                        "device_id_reset": "1"]))
//    }
//
//    func testCustomEventForNewInstallIsOnlySentOnce() {
//        stub(echoDeviceMock) { stub in when(stub.isNewInstall.get).thenReturn(true) }
//
//        config[.idv5Enabled] = "true"
//
//        userPromiseHelper.clearStoredUserData()
//
//        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
//                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
//                                    device: echoDeviceMock, config: config, bbcUser: BBCUser(),
//                                    userPromiseHelper: userPromiseHelper
//        )
//
//        verify(appTagMock, times(1)).notifyHiddenEvent(withLabels: labelsCaptor.capture())
//        assertThat(labelsCaptor.value!, containsLabels(["action_type": "echo_device_id",
//                                                        "action_name": "first_install",
//                                                        "device_id_reset": "1"]))
//
//        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)
//    }

    func testCustomEventNotSentWhenDeviceIdIsNotRegenerated() {
        stub(echoDeviceMock) { stub in when(stub.isNewInstall.get).thenReturn(false) }

        config[.idv5Enabled] = "true"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                device: echoDeviceMock, config: config, bbcUser: BBCUser())

        delegate.start()

        reset(appTagMock)

        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)

        verify(appTagMock, never()).notifyHiddenEvent(withLabels: labelsCaptor.capture())
    }

    func testRemoveHashedIdWhenTokenIsExpired() {
        stub(echoDeviceMock) { stub in when(stub.isNewInstall.get).thenReturn(false) }

        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "true"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: LoggedOut
        )

        delegate.start()
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)

        reset(appTagMock)

        delegate.updateBBCUserLabels(LoggedInExpiredToken)
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                                value: equal(to: nil))
    }

    func testDoesNotReAddHashedIdWhenExpiredUserIsSetAgain() {
        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "true"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: LoggedOut
        )

        delegate.start()
        reset(appTagMock)

        delegate.updateBBCUserLabels(LoggedInExpiredToken)
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                                value: equal(to: nil))

        reset(appTagMock)

        delegate.updateBBCUserLabels(LoggedInExpiredToken)
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                          value: equal(to: "1234"))
    }

    func testSendsHashedIDWhenTokenIsValid() {
        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "true"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: LoggedInExpiredToken
        )

        delegate.start()
        reset(appTagMock)

        delegate.updateBBCUserLabels(LoggedInExpiredToken)
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                                value: equal(to: nil))
        reset(appTagMock)
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                 value: equal(to: "1234"))

    }

    func testBBCHIDIsSentWhenIDV5Enabled() {
        config[.idv5Enabled] = "true"
        
        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser())
        delegate.start()

        reset(appTagMock)
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)
        
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                                                             value: equal(to: "1"))
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                             value: equal(to: "1234"))
    }
    
    func testBBCHIDNotSentWhenIDV5Enabled() {
        config[.idv5Enabled] = "false"
        
        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser())
        delegate.start()

        reset(appTagMock)
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)
        
        verify(appTagMock, atLeastOnce()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                                                             value: equal(to: "1"))
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue),
                                                       value: equal(to: "1234"))
    }

    func testComscoreReset() {
        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "true"
        config[.echoAutoStart] = "false"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser()
        )
        reset(appTagMock)

        delegate.userStateChange()

        verify(appTagMock, atLeastOnce()).clearInternalData()
    }

    func testComscoreResetDisabled() {
        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "false"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser()
        )
        delegate.start()

        reset(appTagMock)
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)

        verify(appTagMock, never()).clearInternalData()
    }

    func testNoComscoreResetWhenUserStateChangesWithHID() {
        verify(appTagMock, never()).clearInternalData()

        stub(echoDeviceMock) { stub in when(stub.isNewInstall.get).thenReturn(false) }
        config[.idv5Enabled] = "true"
        config[.comscoreResetDataOnUserStateChange] = "true"


        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser()
        )
        delegate.start()

        reset(appTagMock)
        delegate.updateBBCUserLabels(LoggedInPersonalisationOn)

        verify(appTagMock, never()).clearInternalData()
    }

    func testCanBeDisabled() {
        delegate.disable()
        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avPlayEvent(at: 10, eventLabels: labelsIn)
        verify(streamSenseMock, never()).notifyPlay(withPosition: equal(to: 10), labels: any())
    }

    func testDisableClearsMedia() {
        delegate.disable()
        // rather than spying on delegate, this tests that a method called by clearMedia() is called
        verify(appTagMock, atLeastOnce()).notifyUXInactive()
    }

    func testCanBeInitialisedAsDisabledThenEnabled() {
        config[.echoEnabled] = "false"
        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser()
        )

        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avPlayEvent(at: 10, eventLabels: labelsIn)
        verify(streamSenseMock, never()).notifyPlay(withPosition: equal(to: 10), labels: any())

        delegate.enable()
        delegate.start()

        delegate.setMedia(mediaOnDemandVideoEpisode)
        delegate.avPlayEvent(at: 10, eventLabels: labelsIn)
        verify(streamSenseMock).notifyPlay(withPosition: equal(to: 10), labels: any())
    }

    func testCanCallMediaMethodsWhenDisabled() {
        config[.echoEnabled] = "false"
        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser()
        )

        delegate.start()

        delegate.setMedia(mediaOnDemandVideoEpisode);
        delegate.setMediaLength(10);
    }

    func testUpdateBBCUserLablesUpdatesPersistentLabelsWithID5() {
        let user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
        config[.echoEnabled] = "false"
        config[.echoAutoStart] = "false"
        config[.idv5Enabled] = "true"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: user
        )

        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                                                       value: equal(to: "1"))
        reset(appTagMock)

        delegate.updateBBCUserLabels(user)
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                                              value: equal(to: "1"))
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue) , value: equal(to: "1234"))
    }

    func testUpdateBBCUserLablesUpdatesPersistentLabelsWithoutID5() {
        let user = BBCUser(signedIn: true, hashedID: "1234", tokenRefreshTimestamp: Date())
        config[.echoEnabled] = "false"
        config[.echoAutoStart] = "false"
        config[.idv5Enabled] = "false"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: user
        )

        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                                                       value: equal(to: "1"))
        reset(appTagMock)

        delegate.updateBBCUserLabels(user)
        verify(appTagMock).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCIDLoggedIn.rawValue),
                                              value: equal(to: "1"))
        verify(appTagMock, never()).setPersistentLabel(withName: equal(to: EchoLabelKeys.BBCHashedID.rawValue) , value: equal(to: "1234"))
    }

    func testDoesNotStartAutomatically() {
        appTagMock = MockComScoreAppTag().withEnabledSuperclassSpy()
        config[.echoAutoStart] = "false"
        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser()
        )

        verify(appTagMock, never()).start()

        delegate.start()

        verify(appTagMock).start()
    }

    func testDeviceIdWhenIDV5IsEnabled () {
        config[.idv5Enabled] = "true"

        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser())

        delegate.start()

        stub(echoDeviceMock) { stub in
            when(stub.getDeviceID()).thenReturn("some-device-id")
        }

        assert(delegate.getDeviceID() == "some-device-id")
    }

    func testDeviceIdWhenCustomDeviceIdIsSet() {
        config[.idv5Enabled] = "false"
        config[.echoDeviceID] = "custom-device-id"
        
        delegate = ComScoreDelegate(appName: appName, appType: .mobileApp,
                                    startCounterName: startCounterName, appTag: appTagMock, streamSense: streamSenseMock,
                                    device: echoDeviceMock, config: config, bbcUser: BBCUser())

        delegate.start()
        assert(delegate.getDeviceID() == "custom-device-id")
    }
}
