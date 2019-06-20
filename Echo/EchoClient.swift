//
//  EchoClient.swift
//  Echo
//
//  Created by Adam Price - myBBC on 25/05/2016.
//  Copyright © 2016 BBC. All rights reserved.
//

import Foundation
import UIKit

public class EchoClient: NSObject, EchoLibrary, LiveProtocol, OnDemandProtocol {

    @objc public static let LibraryName = "echo_ios_swift"
    @objc public static let LibraryVersion = "5.2.1"

    let EchoDeviceIDActionType = "echo_device_id"
    let UserStateChangeAction = "user_state_change"

    private var echoEnabled: Bool = true
    private var autoStart: Bool = true
    private var _hasStarted: Bool = false

    private var brokerFactory: BrokerFactoryProtocol
    private var device: EchoDeviceDelegate
    private var playerDelegate: PlayerDelegate?
    private var broker: Broker?
    private var labelCleanser: LabelCleanser
    private var userPromiseHelper: UserPromiseHelper!

    private var essUrl: String?
    private var essEnabled: Bool = false
    private var useHttps: Bool = false

    internal var delegates: [EchoDelegate]

    internal var media: Media?
    private var mediaActive: Bool = false

    private var suppressingPlayEvent: Bool = false
    private var suppressedPlayEventLabels: [String: String]?

    private var cacheMode: EchoCacheMode

    private var counterNameSet: Bool = false
    private var idv5Enabled: Bool = false

    var previousUser: BBCUser?
    private var bbcUserSetWhileDisabled: BBCUser?
    private var userForTimer: BBCUser?
    private var resetDataOnUserStateChangeEnabled: Bool = false
    private var timer: Timer!

    /**
     Create an instance of Echo.

     - parameters:
        - appName: The name of the containing app
        - appType: The type of the containing app
        - startCounterName: The initial counter name used for reporting
        - config: An optional dictionary containing configuration options
        - bbcUser: An appropriate BBCUser object

     For more information, see [Echo documentation](https://bbc.github.io/echo-docs/documentation/)\.

     */
    @objc public convenience init(appName: String, appType: ApplicationType, startCounterName: String,
                                  config: [EchoConfigKey: String]?, bbcUser: BBCUser = BBCUser()) throws {
        try self.init(appName: appName, appType: appType, startCounterName: startCounterName, config: config,
                          echoDelegateFactory: DefaultDelegateFactory(), device: EchoDevice(),
                          brokerFactory: BrokerFactory(), bbcUser: bbcUser)
    }

    internal init(appName: String, appType: ApplicationType, startCounterName: String, config: [EchoConfigKey: String]?,
                  echoDelegateFactory: EchoDelegateFactoryProtocol, device: EchoDeviceDelegate,
                  brokerFactory: BrokerFactoryProtocol, bbcUser: BBCUser) throws {

        var collatedConfig = EchoClient.collateConfig(config)

        self.brokerFactory = brokerFactory
        self.device = device

        self.labelCleanser = LabelCleanser.getInstance()

        self.essUrl = collatedConfig[.essURL]
        self.useHttps = true

        self.essEnabled = collatedConfig[.useESS] == "true"

        switch collatedConfig[.echoDebug] {
        case "true":
            EchoDebug.isDebugEnabled = true
            EchoDebug.level = .warn
        case "info":
            EchoDebug.isDebugEnabled = true
            EchoDebug.level = .info
        case "warn":
            EchoDebug.isDebugEnabled = true
            EchoDebug.level = .warn
        case "error":
            EchoDebug.isDebugEnabled = true
            EchoDebug.level = .error
        default:
            EchoDebug.isDebugEnabled = false
        }

        self.idv5Enabled = collatedConfig[.idv5Enabled] == "true"

        self.cacheMode = EchoCacheMode.getEnum(collatedConfig[.echoCacheMode] ?? "offline")

        self.echoEnabled = collatedConfig[.echoEnabled] == "true"

        self.autoStart = collatedConfig[.echoAutoStart] == "true"

        let cleanAppName = labelCleanser.cleanLabelValue(EchoLabelKeys.BBCApplicationName.rawValue, value: appName)
        let cleanStartCounterName = labelCleanser.cleanCountername(startCounterName)

        self.userPromiseHelper = UserPromiseHelper(device: self.device, webviewCookiesEnabled: collatedConfig[.webviewCookiesEnabled] == "true")
        var deviceId = collatedConfig[.echoDeviceID] ?? device.getDeviceID()
        if deviceId.trim().isEmpty {
            deviceId = device.getDeviceID()
        }
        if !idv5Enabled {
            self.userPromiseHelper.clearWebviewCookies()
        } else {
            resetDataOnUserStateChangeEnabled = collatedConfig[.comscoreResetDataOnUserStateChange] == "true"
        }
        self.bbcUserSetWhileDisabled = bbcUser

        delegates = echoDelegateFactory.getDelegates(cleanAppName, appType: appType, startCounterName: cleanStartCounterName,
                device: device, config: collatedConfig, bbcUser: bbcUser)

        super.init()
        if !(try EchoClient.isValidConfig(appName: appName, config: collatedConfig)) {
            throw EchoInitialisationError.InvalidConfig(reason: "The provided configuration was invalid.")
        }

        if self.echoEnabled && self.autoStart {
            self.start()
        }

        EchoDebug.log(level: .info, message: "Library initialised")

        NotificationCenter.default.addObserver(self, selector: #selector(EchoClient.appForegrounded), name: UIApplication.willEnterForegroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(EchoClient.appBackgrounded), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func initBroker() {

        if let playerDelegate = playerDelegate, let media = media {

            if let essUrl = essUrl, media.isLive {
                broker = brokerFactory.makeLiveBroker(playerDelegate, media: media, essUrl: essUrl,
                        liveProtocol: self, useHttps: useHttps, essEnabled: essEnabled)
            } else {
                broker = brokerFactory.makeOnDemandBroker(playerDelegate, media: media, onDemandProtocol: self)
            }

            if let broker = broker {
                for delegate in delegates {
                    delegate.setBroker(broker: broker)
                }
            }
        }
    }

    @objc func liveMediaUpdate(_ media: Media, newPosition: UInt64, oldPosition: UInt64) {

        suppressingPlayEvent = false

        self.media = media

        for delegate in delegates {
            delegate.liveMediaUpdate(media, newPosition: newPosition, oldPosition: oldPosition)
        }

    }

    @objc func liveTimestampUpdate(_ timestamp: TimeInterval) {
        let timestamp = UInt64(timestamp * 1000)
        addLabel(EchoLabelKeys.MediaTimestamp.rawValue, value: String(timestamp))
    }

    func setEssError(_ error: EssError, code: String) {
        addLabel(EchoLabelKeys.ESSError.rawValue, value: error.rawValue)

        if error == EssError.StatusCode {
            addLabel(EchoLabelKeys.ESSStatusCode.rawValue, value: code)
        }

        for delegate in delegates {
            delegate.liveEnrichmentFailed()
        }
    }

    @objc func setEssSuccess(_ isSuccess: Bool) {
        addLabel(EchoLabelKeys.ESSSuccess.rawValue, value: isSuccess ? "true" : "false")
    }

    @objc func releaseSuppressedPlay() {
        if !self.echoEnabled {
            return
        }

        if let broker = broker, suppressingPlayEvent {
            suppressingPlayEvent = false
            avPlayEvent(at: (broker.getPosition()), eventLabels: suppressedPlayEventLabels)
        }
    }

    @objc func sendHeartbeat(withName name: String, position: UInt64) {
        avUserActionEvent(actionType: "echo_hb", actionName: name, position: position, eventLabels: nil)
    }

    public func getAPIVersion() -> String {
        return EchoClient.LibraryVersion
    }

    public func getImplementationVersion() -> String {
        return EchoClient.LibraryVersion
    }

    public func getComScoreDeviceID() -> String? {
        var deviceID: String?

        for delegate in delegates {
            delegate.clearMedia()

            if delegate is ComScoreDelegate {
                if let comScoreDeviceID = delegate.getDeviceID() {
                    deviceID = comScoreDeviceID
                }
            }
        }

        return deviceID
    }

    /**
     Set the site used as the reporting destination

     - parameters:
     - site: The Destination Enum representing the site
     */
    @objc public func setDestination(site: Destination) {
        for delegate in delegates {
            delegate.setDestination(site)
        }
    }

    @objc public func setProducer(site: Producer) {
        for delegate in delegates {
            delegate.setProducer(site)
        }
    }

    @objc public func setProducer(name: String) {
        if let producer = Producer.producerFromName(name) {
            for delegate in delegates {
                delegate.setProducer(producer)
            }
        } else {
            EchoDebug.log(level: .warn, message: "Producer name not recognised. Keeping current producer")
        }
    }

    @objc public func setProducerByMasterbrand(_ masterbrandName: String) {
        if let masterbrand = Masterbrand.MasterbrandFromName(masterbrandName) {
            let producer: Producer = masterbrand.producer
            for delegate in delegates {
                delegate.setProducer(producer)
            }
        } else {
            EchoDebug.log(level: .warn, message: "Producer name not recognised. Keeping current producer")
        }
    }

    public func setPlayerName(_ name: String) {

        if !name.trim().isEmpty {

            let name = labelCleanser.cleanLabelValue(EchoLabelKeys.PlayerName.rawValue, value: name)

            for delegate in delegates {
                delegate.setPlayerName(name)
            }
        }
    }

    public func setPlayerVersion(_ version: String) {

        if !version.trim().isEmpty {

            let version = labelCleanser.cleanLabelValue(EchoLabelKeys.PlayerVersion.rawValue, value: version)

            for delegate in delegates {
                delegate.setPlayerVersion(version)
            }
        }
    }

    public func setPlayerDelegate(_ delegate: PlayerDelegate) {
        self.playerDelegate = delegate
    }

    public func setPlayerIsPopped(_ popped: Bool) {
        for delegate in delegates {
            delegate.setPlayerIsPopped(popped)
        }
    }

    public func setPlayerWindowState(_ state: WindowState) {
        for delegate in delegates {
            delegate.setPlayerWindowState(state)
        }
    }

    public func setPlayerVolume(_ volume: Int) {
        if volume >= 0 && volume <= 100 {
            for delegate in delegates {
                delegate.setPlayerVolume(volume)
            }
        } else {
            EchoDebug.log(level: .error, message: "Player volume must be between 1 and 100, supplied: \(volume)")
        }
    }

    public func setPlayerIsSubtitled(_ subtitled: Bool) {
        for delegate in delegates {
            delegate.setPlayerIsSubtitled(subtitled)
        }
    }

    public func setMedia(_ media: Media) {
        if !self.echoEnabled {
            return
        }

        clearMedia()
        let clonedMedia = media.getClone()
        self.media = clonedMedia

        addLabel(EchoLabelKeys.ESSEnabled.rawValue, value: essEnabled ? "true" : "false")

        initBroker()

        if let media = self.media {
            for delegate in delegates {
                delegate.setMedia(media)
            }
        }
    }

    private func clearMedia() {

        removeLabel(EchoLabelKeys.MediaTimestamp.rawValue)
        removeLabel(EchoLabelKeys.ESSEnabled.rawValue)
        removeLabel(EchoLabelKeys.ESSSuccess.rawValue)
        removeLabel(EchoLabelKeys.ESSError.rawValue)
        removeLabel(EchoLabelKeys.ESSStatusCode.rawValue)
        removeLabel(EchoLabelKeys.ESSEnriched.rawValue)

        if media != nil {
            media = nil
        }

        if let broker = broker {
            broker.stop()
            self.broker = nil
        }

        for delegate in delegates {
            delegate.clearMedia()
        }
    }

    public func setMediaLength(_ length: UInt64) {

        if media == nil {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        if self.media?.consumptionMode == .live {
            EchoDebug.log(level: .error, message: "Length should be set to zero prior to passing the media object to Echo for live media")
            return
        }

        if length > 0 {
            for delegate in delegates {
                delegate.setMediaLength(length)
            }
        }

        self.media?.length = length
    }

    @available(iOS, deprecated:2.1.0, message:"Field No longer used")
    public func setMediaBitrate(_ bitrate: UInt64) {
    }

    @available(iOS, deprecated:2.1.0, message:"Field No longer used")
    public func setMediaCodec(_ codec: String) {
    }

    @available(iOS, deprecated:2.1.0, message:"Field No longer used")
    public func setMediaCDN(_ cdn: String) {
    }

    public func avPlayEvent(at position: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        guard let media = self.media else {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        if let broker = broker {

            if media.isLive {
                position = broker.getPosition()
            } else {
                if positionExceedsMediaLength(position) {
                    return
                }

                broker.setPosition(position)
            }

            broker.start()
        }

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        if media.isLive && media.isEnrichedWithESSData && suppressingPlayEvent {
            suppressedPlayEventLabels = sanitisedLabels
        } else {
            for delegate in delegates {
                delegate.avPlayEvent(at: position, eventLabels: sanitisedLabels)
            }
            self.media?.isPlaying = true
            self.media?.isBuffering = false
            mediaActive = true
        }
    }

    public func avPauseEvent(at position: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        guard let media = self.media else {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        position = avNavigationEvent(position: position)

        media.isPlaying = false

        for delegate in delegates {
            delegate.avPauseEvent(at: position, eventLabels: sanitisedLabels)
        }

    }

    public func avBufferEvent(at position: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        guard let media = self.media else {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        position = avNavigationEvent(position: position)

        media.isPlaying = false

        for delegate in delegates {
            delegate.avBufferEvent(at: position, eventLabels: sanitisedLabels)
        }

        media.isBuffering = true

    }

    public func avEndEvent(at position: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        guard media != nil else {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        position = avNavigationEvent(position: position)

        self.media?.isPlaying = false

        for delegate in delegates {
            delegate.avEndEvent(at: position, eventLabels: sanitisedLabels)
        }

        self.media = nil
        mediaActive = false

    }

    public func avRewindEvent(at position: UInt64, rate: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        if media == nil {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        position = avNavigationEvent(position: position)

        for delegate in delegates {
            delegate.avRewindEvent(at: position, rate: rate, eventLabels: sanitisedLabels)
        }

    }

    public func avFastForwardEvent(at position: UInt64, rate: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        if media == nil {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        position = avNavigationEvent(position: position)

        for delegate in delegates {
            delegate.avFastForwardEvent(at: position, rate: rate, eventLabels: sanitisedLabels)
        }

    }

    public func avSeekEvent(at position: UInt64, eventLabels: [String: String]?) {
        // Note that seeks are not treated like pauses in the ATI delegate as opposed to the Comscore delegate
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position)")

        if media == nil {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        position = avNavigationEvent(position: position)

        for delegate in delegates {
            delegate.avSeekEvent(at: position, eventLabels: sanitisedLabels)
        }
    }

    public func avUserActionEvent(actionType: String, actionName: String, position: UInt64, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        EchoDebug.log(level: .info, message: "\(#function) called with position: \(position), name: \(actionName), type: \(actionType)")

        if media == nil {
            EchoDebug.log(level: .error, message: "setMedia() must be called before" + #function)
            return
        }

        var position = position

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        if let broker = broker, let media = media {
            if media.isLive {
                position = broker.getPosition()
            } else {
                position = preventPositionExceedingMediaLength(position)
            }
        }

        for delegate in delegates {
            delegate.avUserActionEvent(actionType: actionType, actionName: actionName, position: position, eventLabels: sanitisedLabels)
        }
    }

    private func avNavigationEvent(position: UInt64) -> UInt64 {
        var position = position

        if let media = media {
            if let broker = broker {
                broker.stop()

                if media.isLive {
                    position = broker.getPosition()
                } else {
                    position = preventPositionExceedingMediaLength(position)
                }
            }

            if media.isLive && media.isEnrichedWithESSData && !suppressingPlayEvent {
                suppressingPlayEvent = true
            }
        }
        return position
    }

    public func setCacheMode(_ cacheMode: EchoCacheMode) {

        if !mediaActive {
            for delegate in delegates {
                delegate.setCacheMode(cacheMode)
            }
            self.cacheMode = cacheMode
        } else {
            EchoDebug.log(level: .error, message: "Cannot call setCacheMode() after avPlayEvent() and before avEndEvent()")
        }
    }

    public func getCacheMode() -> EchoCacheMode {
        return cacheMode
    }

    public func flushCache() {
        if !self.echoEnabled {
            return
        }

        for delegate in delegates {
            delegate.flushCache()
        }
    }

    /**
     Clear Echo's cache. Echo will delete all data from its cache without sending it.

     For more information, see the [Echo documentation](https://bbc.github.io/echo-docs/documentation/)\.

     */
    public func clearCache() {
        for delegate in delegates {
            delegate.clearCache()
        }
    }

    public func setContentLanguage(_ language: String) {
        for delegate in delegates {
            delegate.setContentLanguage(language)
        }
    }

    public func setCounterName(_ counterName: String) {

        let counterName = labelCleanser.cleanCountername(counterName)

        counterNameSet = true

        for delegate in delegates {
            delegate.setCounterName(counterName)
        }
    }

    func resetUserData(_ user: BBCUser, _ deviceIDResetReason: DeviceIDResetReason?) {
        if user.tokenState() == .valid {
            if deviceIDResetReason != nil {
                EchoDebug.log(level: .info, message: "Clearing cache and internal data due to session and device id change")
                self.clearCache()
            }
            if let tokenRefreshTimestamp = user.tokenRefreshTimestamp {
                scheduleTokenExpiry(tokenRefreshTimestamp, user: user)
            }
        } else if user.tokenState() == .expired && previousUser?.tokenState() != .expired {
            // changing state from valid (or none) to expired
            EchoDebug.log(level: .info, message: "changing state from valid (or none) to expired")
            removeSchedule()
        }
    }

    fileprivate func resetDeviceId(_ deviceIDResetReason: DeviceIDResetReason, _ userPromiseHelperResult: UserPromiseHelperResult) {
        if resetDataOnUserStateChangeEnabled && deviceIDResetReason == .userStateChange {
            for delegate in delegates {
                delegate.userStateChange()
            }
            // we can not send the 'user_state_change' event so persist the state change event type
            // so it can be picked up the next time Echo starts
            self.userPromiseHelper.setPostponedUserStateTransition(userStateTransition: userPromiseHelperResult.userStateTransition)
            return
        }
    }

    fileprivate func sendUserUpdateEvent(_ user: BBCUser, _ actionType: String, _ actionName: String, _ eventLabels: inout [String: String], _ userPromiseHelperResult: UserPromiseHelperResult) {
        if userPromiseHelperResult.isPostponedUserStateChange {
            eventLabels = ["device_id_reset": "1"]
        }
        for delegate in delegates {
            eventLabels[EchoLabelKeys.IsBackground.rawValue] = "true"
            delegate.userActionEvent(actionType: actionType, actionName: actionName, eventLabels: eventLabels)
        }
        // Inform the user promise helper that we have handled the postponed user state change type
        // This ensures that the persistent data is cleared and we only send the event once
        if userPromiseHelperResult.isPostponedUserStateChange {
            userPromiseHelper.clearPostponedUserStateTransition()
        }
    }

    func userShouldUpdate(_ user: BBCUser) -> Bool {
        if !self.eventsEnabled() {
            self.bbcUserSetWhileDisabled = user
            return false
        }

        if !idv5Enabled {
            previousUser = user
            return false
        }
        return true
    }

    @objc public func setBBCUser(_ user: BBCUser) {
        var userPromiseHelperResult: UserPromiseHelperResult
        var deviceIDResetReason: DeviceIDResetReason?
        var actionType: String = UserStateChangeAction
        var actionName: String
        var eventLabels = [String: String]()

        //return if disabled or idv5 disabled
        guard userShouldUpdate(user) else {
            return
        }

        // set previous user from local storage if not already set
        previousUser = previousUser ?? userPromiseHelper.getBBCUser()

        // update local storage based on incoming user
        userPromiseHelperResult = userPromiseHelper.setBBCUser(user)
        deviceIDResetReason = userPromiseHelperResult.deviceIDResetReason
        actionName = userPromiseHelperResult.userStateTransition.rawValue

        if let deviceID = userPromiseHelper.getDeviceID() {
            for delegate in delegates {
                delegate.updateDeviceID(deviceID)
            }
        }

        //should delegates be disabled due to user state change?
        if resetDataOnUserStateChangeEnabled {
            //reset the delegate, stop sending events, postpone user event.
            resetUserData(user, deviceIDResetReason)
        }

        //reset the device id and update event labels, name and type
        if let deviceIDResetReason = deviceIDResetReason {
            resetDeviceId(deviceIDResetReason, userPromiseHelperResult)
            if resetDataOnUserStateChangeEnabled && deviceIDResetReason == .userStateChange {
                return
            }
            if deviceIDResetReason != .firstInstall || userPromiseHelperResult.isPostponedUserStateChange {
                eventLabels = ["device_id_reset": "1"]
            }
            if userPromiseHelperResult.userStateTransition == .none || deviceIDResetReason == .firstInstall || deviceIDResetReason == .echoUpgrade {
                actionType = EchoDeviceIDActionType
                actionName = deviceIDResetReason.rawValue
            }
        }

        //update user labels stored in delegate
        for delegate in delegates {
            delegate.updateBBCUserLabels(user)
        }

         if userPromiseHelperResult.userStateTransition != .none || userPromiseHelperResult.deviceIDResetReason != nil {
            sendUserUpdateEvent(user, actionType, actionName, &eventLabels, userPromiseHelperResult)
        }

        // the incoming user will subsequently be the previous user
        previousUser = user
        //bbcUserSetWhileDisabled should now be nil
        self.bbcUserSetWhileDisabled = nil
    }

    public func addManagedLabel(_ label: ManagedLabel, value: String) {

        if !value.isEmpty {
            let cleansedValue = labelCleanser.cleanLabelValue(label.name(), value: value)

            for delegate in delegates {
                delegate.addManagedLabel(label, value: cleansedValue)
            }
        }
    }

    public func addLabels(_ labels: [String: String]) {

        let sanitisedLabels = sanitiseLabels(labels)

        for delegate in delegates {
            delegate.addLabels(sanitisedLabels)
        }

    }

    public func addLabel(_ key: String, value: String) {
        addLabels([key: value])
    }

    public func removeLabels(_ labels: [String]) {

        let keys = sanitiseLabels(labels)

        if !keys.isEmpty {
            for delegate in delegates {
                delegate.removeLabels(keys)
            }
        }
    }

    public func removeLabel(_ key: String) {
        removeLabels([key])
    }

    public func setTraceID(_ trace: String) {
        for delegate in delegates {
            delegate.setTraceID(trace)
        }
    }

    @objc func appForegrounded() {
        for delegate in delegates {
            delegate.appForegrounded()
        }
    }

    @objc func appBackgrounded() {
        for delegate in delegates {
            delegate.appBackgrounded()
        }
    }

    public func viewEvent(counterName: String, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        let cleansedCounterName = labelCleanser.cleanCountername(counterName)

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        counterNameSet = true

        for delegate in delegates {
            delegate.viewEvent(counterName: cleansedCounterName, eventLabels: sanitisedLabels)
        }
    }

    public func userActionEvent(actionType: String, actionName: String, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        if !counterNameSet {
            EchoDebug.log(level: .error, message: "userActionEvent not available before a call to viewEvent (to set counter name).")
            return
        }

        var sanitisedLabels: [String: String]?

        if let eventLabels = eventLabels {
            sanitisedLabels = sanitiseLabels(eventLabels)
        }

        // No clean up of actionType and actionName as they are values
        // which will get put against keys. We don't clean values.

        for delegate in delegates {
            delegate.userActionEvent(actionType: actionType, actionName: actionName, eventLabels: sanitisedLabels)
        }
    }

    public func errorEvent(_ error: String, eventLabels: [String: String]?) {
        if !self.echoEnabled {
            return
        }

        var eventLabels = eventLabels

        if let labels = eventLabels {
            eventLabels = sanitiseLabels(labels)
        }

        for delegate in delegates {
            delegate.errorEvent(error, eventLabels: eventLabels)
        }
    }

    private func sanitiseLabels(_ labels: [String]) -> [String] {

        var cleanedKeys = [String]()

        for key in labels {
            let cleanKey = labelCleanser.cleanLabelKey(key)

            if !cleanKey.isEmpty {
                cleanedKeys.append(cleanKey)
            }
        }

        return cleanedKeys
    }

    public func enable() {
        if self.echoEnabled {
            return
        }

        self.echoEnabled = true

        for delegate in delegates {
            delegate.enable()
        }

        if let user = self.bbcUserSetWhileDisabled, hasStarted {
            self.setBBCUser(user)
            self.bbcUserSetWhileDisabled = nil
        }

        if self.autoStart && !self.hasStarted {
            self.start()
        }
    }

    public func disable() {
        if !self.echoEnabled {
            return
        }

        self.clearMedia()
        self.echoEnabled = false

        for delegate in delegates {
            delegate.disable()
        }
    }

    public func start() {
        if !self.echoEnabled || self.hasStarted {
            return
        }

        for delegate in delegates {
            delegate.start()
        }

        self._hasStarted = true
        if let user = self.bbcUserSetWhileDisabled {
            self.setBBCUser(user)
        }
    }

    @objc public func isEnabled() -> Bool {
        return self.echoEnabled
    }

    @objc internal func sanitiseLabels(_ labels: [String: String]) -> [String: String] {

        var sanitisedLabels = [String: String]()

        for (key, value) in labels {
            let cleanKey = labelCleanser.cleanLabelKey(key)
            let cleanValue = labelCleanser.cleanLabelValue(cleanKey, value: value)
            sanitisedLabels[cleanKey] = cleanValue
        }

        return sanitisedLabels
    }

    private class func collateConfig(_ userConfig: [EchoConfigKey: String]?) -> [EchoConfigKey: String] {

        var config = [EchoConfigKey: String]()

        // Get default Echo config
        config.merge(getDefaultConfig())

        // Get defaults for each delegate
        config.merge(ComScoreDelegate.getDefaultConfig())
        config.merge(SpringDelegate.getDefaultConfig())
        config.merge(ATInternetDelegate.getDefaultConfig())

        // Check if user has provided configuration
        if let userConfig = userConfig {

            // Get reporting profile data and add to config
            if let profile = userConfig[.reportingProfile],
               let echoProfile = EchoProfile(rawValue: profile.lowercased()) {
                config.merge(EchoReportingProfiles.getConfigForProfile(echoProfile))
            }

            // Add user provided overrides where appropriate
            for (key, value) in userConfig where !value.isEmpty {
                config[key] = value
            }
        }

        // These are set last as a user should not be able to override them
        config[.measurementLibName] = EchoClient.LibraryName
        config[.measurementLibVersion] = EchoClient.LibraryVersion

        return config
    }

    @objc internal class func getDefaultConfig() -> [EchoConfigKey: String] {
        var config = [EchoConfigKey: String]()
        config[.echoEnabled] = "true"
        config[.echoAutoStart] = "true"
        config[.echoDebug] = "false"
        config[.essURL] = "ess.api.bbci.co.uk"
        config[.useESS] = "false"
        config[.essHTTPSEnabled] = "true"
        config[.echoCacheMode] = EchoCacheMode.offline.name()

        return config
    }

    private func preventPositionExceedingMediaLength(_ position: UInt64) -> UInt64 {
        if let media = media {
            if positionExceedsMediaLength(position) {
                return media.length
            }
        }

        return position
    }

    /**
     Validates the provided application name, application type and configuration.
     - parameters:
        - appName: The application name
        - appType: The app type
        - config: The collection of custom configurations
    */
    private class func isValidConfig(appName: String, config: [EchoConfigKey: String]) throws -> Bool {
        // Echo Enabled - Must be true or false
        let boolValid = ["true", "false"]
        guard validateConfigField(key: .echoEnabled, value: config[.echoEnabled], valid: boolValid, options: []),
              // Echo Auto-Start - Must be true or false
              validateConfigField(key: .echoAutoStart, value: config[.echoAutoStart], valid: boolValid, options: []),
              // Application Name - Can't be null, empty or only whitespace.
              validateConfigField(key: .applicationName, value: appName, valid: [], options: [.nonZeroLength, .noWhiteSpace]),
              // Cache mode must be a permitted value
              validateConfigField(key: .echoCacheMode, value: config[.echoCacheMode], valid: ["offline", "all"], options: []),
              // comscore enabled must be true or false
              validateConfigField(key: .comScoreEnabled, value: config[.comScoreEnabled], valid: boolValid, options: [.optional]),
              // comscore debug more must be "0" or "1"
              validateConfigField(key: .comScoreDebugMode, value: config[.comScoreDebugMode], valid: ["0", "1"], options: [.optional]),
              // test service enabled must be true or false
              validateConfigField(key: .testServiceEnabled, value: config[.testServiceEnabled], valid: boolValid, options: [.optional]),
              // use ess must be true or false
              validateConfigField(key: .useESS, value: config[.useESS], valid: boolValid, options: []),
              // ess_https_enabled must be true or false
              validateConfigField(key: .essHTTPSEnabled, value: config[.essHTTPSEnabled], valid: boolValid, options: []),
              // idv5_enabled must be true or false
              validateConfigField(key: .idv5Enabled, value: config[.idv5Enabled], valid: boolValid, options: [.optional]),
              // webview cookies enabled must be true or false,
              validateConfigField(key: .webviewCookiesEnabled, value: config[.webviewCookiesEnabled], valid: boolValid, options: [.optional]),
              // barbEnabled must be true or false
              validateConfigField(key: .barbEnabled, value: config[.barbEnabled], valid: boolValid, options: [.optional])
        else {
            return false
        }

        return true
    }

    /**
     validates that a given value is valid against a supplied list of valid values.
     Providing an empty list treats treats all strings as valid unless additional rules in options are met.
     Additional rules test for non zero and no white space.
    */
    private class func validateConfigField(key: EchoConfigKey, value: String?, valid: [String], options: [EchoConfigValidationOptions]) -> Bool {
        if options.contains(.optional) && value == nil {
            return true
        } else if !options.contains(.optional) && value == nil {
            EchoDebug.log(level: .error, message: "Missing Config Argument: \(key)")
            return false
        }

        guard let value = value else {
            return false
        }

        if options.contains(.nonZeroLength) {
            if value.count == 0 {
                EchoDebug.log(level: .error, message: "\(key) cannot be empty. Not Valid: \(value)")
                return false
            }
        }

        if options.contains(.noWhiteSpace) {
            if value.range(of: "\\A\\s*\\z", options: .regularExpression) != nil {
                EchoDebug.log(level: .error, message: "\(key) cannot be empty. Not Valid: \(value)")
                return false
            }
        }

        if valid.count == 0 || valid.contains(value) {
            return true
        } else {
            EchoDebug.log(level: .error, message: "\(key) must equal one of \(valid). Not valid: \(value)")
            return false
        }
    }

    private func positionExceedsMediaLength(_ position: UInt64) -> Bool {
        // return true if the position exceeds, or is within one second of, the total length of the playing media
        // necessary to check length is at least 1000 to avoid a crash because unsigned ints can't be negative
        if let media = media {
            if media.length >= 1000 && position >= (media.length - 1000) {
                return true
            }

            if media.length < 1000, media.length != 0 {
                return true
            }
        }

        return false
    }

    private func eventsEnabled() -> Bool {
        return self.echoEnabled && self.hasStarted
    }

    private func scheduleTokenExpiry(_ tokenRefreshTimestamp: Date, user: BBCUser) {
        // stop existing schedule (waiting for new token)
        removeSchedule()

        let timeUntilExpiry = user.getTimeUntilTokenExpiry()

        // can't pass user object through timer as it has optionals which aren't objc compatible
        // so we assign it to a global variable so the expireToken method can read it
        userForTimer = user

        if timeUntilExpiry > 0 {
            timer = Timer(timeInterval: timeUntilExpiry,
                          target: self,
                          selector: #selector(expireToken),
                          userInfo: nil,
                          repeats: false)

            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

            EchoDebug.log(level: .info, message: "Scheduler set to check token in \(timeUntilExpiry) seconds")
        }

    }

    @objc private func expireToken() {
        if let userForTimer = userForTimer {
            for delegate in delegates {
                delegate.updateBBCUserLabels(userForTimer)
            }
        }
        userForTimer = nil
    }

    private func removeSchedule() {
        if let timer = timer {
            timer.invalidate()
        }
    }

    @objc public var hasStarted: Bool {
        return self._hasStarted
    }

}
