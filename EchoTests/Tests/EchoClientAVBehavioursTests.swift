//
// Created by James Owen on 15/04/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import Hamcrest

class EchoClientAVBehavioursTests: EchoClientTests {

//
// Created by James Owen on 12/04/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

    override func setUp() {
        super.setUp()
    }

    // -Media player methods---------------------------------------------------

    func testSetPlayerNameCallsDelegates() {

        let playerName = "my-iplayer"

        // MUT
        client.setPlayerName(playerName)

        // Delegated to mock 1?
        verify(mock1).setPlayerName(equal(to: playerName))

        // Delegated to mock 2?
        verify(mock2).setPlayerName(equal(to: playerName))
    }

    func testSetPlayerNameDiscardsEmptyVals() {

        // MUT
        client.setPlayerName("")
        client.setPlayerName("              ")

        // None of the above should result in calls to delegates - they should
        // be discarded
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testSetPlayerVersionCallsDelegates() {

        let playerVersion = "1.0.3 r3"

        // MUT
        client.setPlayerVersion(playerVersion)

        // Delegated to mock 1?
        verify(mock1).setPlayerVersion(equal(to: playerVersion))

        // Delegated to mock 2?
        verify(mock2).setPlayerVersion(equal(to: playerVersion))
    }

    func testSetPlayerVersionDiscardsEmptyVals() {

        // MUT
        client.setPlayerVersion("")
        client.setPlayerVersion("              ")

        // None of the above should result in calls to delegates - they should
        // be discarded
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testSetPlayerPoppedCallsDelegates() {

        client.setPlayerIsPopped(true)

        // Delegated to mock 1?
        verify(mock1).setPlayerIsPopped(true)
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).setPlayerIsPopped(true)
        verifyNoMoreInteractions(mock2)
    }

    func testSetPlayerSubtitledCallsDelegates() {

        client.setPlayerIsSubtitled(true)

        // Delegated to mock 1?
        verify(mock1).setPlayerIsSubtitled(true)
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).setPlayerIsSubtitled(true)
        verifyNoMoreInteractions(mock2)
    }

    func testSetPlayerWindowStateCallsDelegates() {

        // MUT
        let windowState = WindowState.maximised
        client.setPlayerWindowState(windowState)

        // Delegated to mock 1?
        verify(mock1).setPlayerWindowState(equal(to: windowState))
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).setPlayerWindowState(equal(to: windowState))
        verifyNoMoreInteractions(mock2)
    }

    func testSetPlayerWindowStateDiscardsNulls() {

        //not possible to set window state to nil in swift
    }

    func testSetPlayerVolumeCallsDelegates() {

        let volume = 50

        // MUT
        client.setPlayerVolume(volume)

        // Delegated to mock 1?
        verify(mock1).setPlayerVolume(equal(to: volume))
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).setPlayerVolume(equal(to: volume))
        verifyNoMoreInteractions(mock2)
    }

    func testSetPlayerVolumeDiscardsOutOfRangeVals() {
        // MUT
        client.setPlayerVolume(101)
        verify(mock1, never()).setPlayerVolume(equal(to: 100))
        verify(mock2, never()).setPlayerVolume(equal(to: 100))

        // MUT
        client.setPlayerVolume(-1)
        verify(mock1, never()).setPlayerVolume(equal(to: 0))
        verify(mock2, never()).setPlayerVolume(equal(to: 0))
    }


// -Media metadata methods-------------------------------------------------

// -Testing EchoClient.setMedia method----------------------
    func testSetMediaCallsDelegates() {
        let mediaCaptor = ArgumentCaptor<Media>()

        // Echo client requires that the view method is called before setting
        // content ID
        doViewPreReqs()

        // MUT
        client.setMedia(mediaOnDemandClip)

        // Delegated to mock 1?
        verify(mock1).setMedia(mediaCaptor.capture())
        verify(mock1, atLeastOnce()).removeLabels(any())
        assert(mediaCaptor.value!.consumptionMode == .onDemand)

        // Delegated to mock 2?
        verify(mock2).setMedia(mediaCaptor.capture())
        verify(mock2, atLeastOnce()).removeLabels(any())
        assert(mediaCaptor.value!.consumptionMode == .onDemand)
    }

    func testSetMediaPassesDelegatesACloneOfMedia() {

        let mediaCaptor = ArgumentCaptor<Media>()

        // Echo client requires that the view method is called before setting
        // content ID
        doViewPreReqs()

        // MUT
        client.setMedia(mediaLiveEpisode)

        // Delegated to mock 1?
        verify(mock1).setMedia(mediaCaptor.capture())

        let capturedMedia = mediaCaptor.value

        // Check the captured media is a clone (same attributes) but not the
        // same object
        let isNotTheSameObject = mediaLiveEpisode !== capturedMedia
        assert(isNotTheSameObject)

        assert(mediaLiveEpisode.avType == capturedMedia?.avType)
        assert(mediaLiveEpisode.versionID == capturedMedia?.versionID)
        assert(mediaLiveEpisode.serviceID == capturedMedia?.serviceID)
        assert(mediaLiveEpisode.consumptionMode == capturedMedia?.consumptionMode)

        assert(mediaLiveEpisode.retrievalType == capturedMedia?.retrievalType)
        assert(mediaLiveEpisode.length == capturedMedia?.length)

        // Delegated to mock 2?
        verify(mock2).setMedia(mediaCaptor.capture())
        verify(mock2, atLeastOnce()).removeLabels(any())

        // Check the captured media from the second delegate was same as first
        assert(capturedMedia === mediaCaptor.value)
    }

    func testSetMediaPreReqsViewEvent() {

        // Not calling view event before trying to set Media

        // MUT
        client.setMedia(mediaLiveClip)
        verify(mock1, atLeastOnce()).removeLabels(any())
        verify(mock2, atLeastOnce()).removeLabels(any())
    }

    func testSetMediaIgnoresInvalidMediaObject() {

        // MUT
        client.setMedia(invalidMedia)

        verify(mock1, atLeastOnce()).removeLabels(any())
        verify(mock2, atLeastOnce()).removeLabels(any())
    }

// -Testing EchoClient.setMediaLength methods----------------------

// Set media length calls delegates
// Set media length pre-reqs set media

// Set media length ignored if length already set on Media
// Set media length ignored if called more than once

// Live content
// Set media length ignored for live content (as should be set / left
// default on Media object)

// On-demand content
// Set media length ignores negative values for on-demand content
// Set media length ignores zero values for on-demand content

    func testSetMediaLengthCallsDelegates() {

        // Set counter name and media object
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.setMediaLength(500)

        // Delegated to mock 1?
        verify(mock1).setMediaLength(equal(to: 500))
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).setMediaLength(equal(to: 500))
        verifyNoMoreInteractions(mock2)
    }

    func testSetMediaLengthPreReqsSetMedia() {

        doViewPreReqs()
        // Not calling setMedia

        client.setMediaLength(500)

        // Shouldn't get passed to delegates
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testSetMediaLengthIgnoredIfCalledAtAllForLiveContent() {
        /*
         * Should be ignored as for live media, it can be set / left as default
         * on the media object before it is passed to EchoClient.
         */
        doViewPreReqs()

        client.setMedia(mediaLiveEpisode)

        // Reset mocks so we can see side effects on just MUT
        reset(mock1, mock2)

        // MUT
        client.setMediaLength(0)
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)

        // Also check positive values
        client.setMediaLength(1)
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testSetMediaLengthAllowedIfCalledMoreThanOnceForOnDemand() {

        doViewAndOnDemandMediaPreReqs()

        client.setMediaLength(500)

        // Reset mocks so we can check side effects of calling again
        reset(mock1, mock2)

        // MUT - Should be ignored
        client.setMediaLength(500)

        verify(mock1).setMediaLength(equal(to: 500))
        verify(mock2).setMediaLength(equal(to: 500))
    }

    func testSetMediaLengthIgnoresZeroLengthsForOnDemand() {

        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.setMediaLength(0)

        // Shouldn't get passed through
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

// --Media event methods---------------------------------------------------

    func testAvPlayEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avPlayEvent(at: 10, eventLabels: dirtyLabelsIn)
        XCTAssertEqual(client.media?.isPlaying, true)

        // Delegated to mock 1?
        verify(mock1).avPlayEvent(at: equal(to: 10), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avPlayEvent(at: equal(to: 10), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvPauseEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avPauseEvent(at: 20, eventLabels: dirtyLabelsIn)
        
        // Validate media play event state
        XCTAssertEqual(client.media?.isPlaying, false)

        // Delegated to mock 1?
        verify(mock1).avPauseEvent(at: equal(to: 20), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avPauseEvent(at: equal(to: 20), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvBufferEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avBufferEvent(at: 40, eventLabels: dirtyLabelsIn)
        
        // Validate media play event state
        XCTAssertEqual(client.media?.isPlaying, false)

        // Delegated to mock 1?
        verify(mock1).avBufferEvent(at: equal(to: 40), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avBufferEvent(at: equal(to: 40), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvEndEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avEndEvent(at: 50, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avEndEvent(at: equal(to: 50), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        XCTAssertEqual(client.media, nil)
        
        // Delegated to mock 2?
        verify(mock2).avEndEvent(at: equal(to: 50), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvRewindEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avRewindEvent(at: 70, rate: 2, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avRewindEvent(at: equal(to: 70), rate: equal(to: 2), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avRewindEvent(at: equal(to: 70), rate: equal(to: 2), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvFastForwardEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avFastForwardEvent(at: 90, rate: 3, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avFastForwardEvent(at: equal(to: 90), rate: equal(to: 3), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avFastForwardEvent(at: equal(to: 90), rate: equal(to: 3), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvSeekEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avSeekEvent(at: 110, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avSeekEvent(at: equal(to: 110), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avSeekEvent(at: equal(to: 110), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvUserActionEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        let eventType = "aType"
        let eventDesc = "aName"

        // MUT
        client.avUserActionEvent(actionType: eventType, actionName: eventDesc, position: 130, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avUserActionEvent(
                actionType: eventType,
                actionName: eventDesc,
                position: equal(to: 130),
                eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avUserActionEvent(
                actionType: equal(to: eventType),
                actionName: equal(to: eventDesc),
                position: equal(to: 130),
                eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvErrorEventCallsDelegates() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.errorEvent("1000", eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).errorEvent(equal(to: "1000"), eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock1).errorEvent(equal(to: "1000"), eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvPlayEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avPlayEvent(at: 10, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvPauseEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avPauseEvent(at: 20, eventLabels: dirtyLabelsIn)

        // Delegates should not be called in either case
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvBufferEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avBufferEvent(at: 40, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvEndEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avEndEvent(at: 50, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvRewindEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avRewindEvent(at: 70, rate: 2, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvFastForwardEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avFastForwardEvent(at: 90, rate: 3, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvSeekEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avSeekEvent(at: 110, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testAvUserActionEventPreReqsEnforced() {

        // Do not set the required Media object - just counter name
        doViewPreReqs()

        // MUT
        client.avUserActionEvent(actionType: "aType", actionName: "aName", position: 130, eventLabels: dirtyLabelsIn)

        // Delegates should not be called
        verifyNoMoreInteractions(mock1)
        verifyNoMoreInteractions(mock2)
    }

    func testSetMediaUpdatesBrokerWhenOnDemand() {
        // Echo client requires that the view method is called before setting
        // content ID
        doViewPreReqs()

        client.setMedia(mediaOnDemandClip)

        verify(mock1, atLeastOnce()).setBroker(broker: any())
    }

    func testSetMediaUpdatesBrokerWhenLive() {
        // Echo client requires that the view method is called before setting
        // content ID
        doViewPreReqs()

        client.setMedia(mediaLiveEpisode)

        verify(mock1, atLeastOnce()).setBroker(broker: any())
    }

    func testAvPlayEventValidatesPosition() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avPlayEvent(at: 0, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avPlayEvent(at: equal(to: 0), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avPlayEvent(at: equal(to: 0), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testAvSeekEventValidatesPosition() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()

        // MUT
        client.avSeekEvent(at: 0, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avSeekEvent(at: equal(to: 0), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avSeekEvent(at: equal(to: 0), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testShouldNotDelegatePlayEventWhenPositionExceedsMediaLength() {
        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()
        client.setMediaLength(5000)

        // Reset mocks so we can see side effects on just MUT
        reset(mock1, mock2)

        // MUT
        client.avPlayEvent(at: 10000, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1, never()).avPlayEvent(at: any(), eventLabels: any())
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock1, never()).avPlayEvent(at: any(), eventLabels: any())
        verifyNoMoreInteractions(mock2)
    }

    func testShouldNotExceedMediaLength() {

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()
        client.setMediaLength(5000)

        // Reset mocks so we can see side effects on just MUT
        reset(mock1, mock2)

        // MUT
        client.avSeekEvent(at: 10000, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avSeekEvent(at: equal(to: 5000), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock1)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avSeekEvent(at: equal(to: 5000), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testUserActionEventPositionShouldNotExceedMediaLength() {
        let eventType = "aType"
        let eventDesc = "aName"

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()
        client.setMediaLength(5000)

        // MUT
        client.avUserActionEvent(actionType: eventType, actionName: eventDesc, position: 10000, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avUserActionEvent(
            actionType: eventType,
            actionName: eventDesc,
            position: equal(to: 5000),
            eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avUserActionEvent(
            actionType: equal(to: eventType),
            actionName: equal(to: eventDesc),
            position: equal(to: 5000),
            eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testPositionIsReportedAsMediaLengthWhenWithinOneSecondCapLimit() {
        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()
        client.setMediaLength(10000)

        // Reset mocks so we can see side effects on just MUT
        reset(mock1, mock2)

        // MUT
        client.avSeekEvent(at: 9000, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avSeekEvent(at: equal(to: 10000), eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
        verifyNoMoreInteractions(mock1)

        // Delegated to mock 2?
        verify(mock2).avSeekEvent(at: equal(to: 10000), eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
        verifyNoMoreInteractions(mock2)
    }

    func testUserActionEventPositionIsReportedAsMediaLengthWhenWithinOneSecondCapLimit() {
        let eventType = "aType"
        let eventDesc = "aName"

        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()
        client.setMediaLength(10000)

        // MUT
        client.avUserActionEvent(actionType: eventType, actionName: eventDesc, position: 9000, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avUserActionEvent(
            actionType: eventType,
            actionName: eventDesc,
            position: equal(to: 10000),
            eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avUserActionEvent(
            actionType: equal(to: eventType),
            actionName: equal(to: eventDesc),
            position: equal(to: 10000),
            eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testMediaLengthLessThan1000AlwaysReturnsLength() {
        // Pre-reqs for use of av event methods
        doViewAndOnDemandMediaPreReqs()
        client.setMediaLength(800)

        // Reset mocks so we can see side effects on just MUT
        reset(mock1, mock2)

        // MUT
        client.avSeekEvent(at: 500, eventLabels: dirtyLabelsIn)

        // Delegated to mock 1?
        verify(mock1).avSeekEvent(at: equal(to: 800), eventLabels: optionalDictionaryCaptor.capture())
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)

        // Delegated to mock 2?
        verify(mock2).avSeekEvent(at: equal(to: 800), eventLabels: optionalDictionaryCaptor.capture())
        verifyNoMoreInteractions(mock2)
        assertLabelsOutIncludeCleanedLabelsIn(labelsOut: optionalDictionaryCaptor.value!!)
    }

    func testSupressedPlayDoesNotSetMediaPlaying(){
        doViewPreReqs()
        mediaLiveClip.isEnrichedWithESSData = true
        client.setMedia(mediaLiveClip)
        client.avPlayEvent(at: 10, eventLabels: nil)
        client.avPauseEvent(at: 20, eventLabels: nil)
        client.avPlayEvent(at: 30, eventLabels: nil)
        XCTAssertEqual(false, client.media?.isPlaying)
        client.releaseSuppressedPlay()
        XCTAssertEqual(true, client.media?.isPlaying)
    }

    func doViewPreReqs() {
        client.viewEvent(counterName: "news.page", eventLabels: nil)
        reset(mock1, mock2)
    }

    func doViewAndLiveMediaPreReqs() {
        doViewPreReqs()
        client.setMedia(mediaLiveClip)
        reset(mock1, mock2, mock3)
    }

    func doViewAndOnDemandMediaPreReqs() {
        doViewPreReqs()
        // have to set a length or bad things happen
        let media = mediaOnDemandClip
        media.length = 10000
        client.setMedia(media)
        reset(mock1, mock2, mock3)
    }


}


