//
//  File.swift
//  EchoTests
//
//  Created by Andrew Ryan on 28/08/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import Foundation

class EchoDelegateMock: EchoDelegate{
    func clearCache() {
        
    }

    func updateDeviceID(_ deviceId: String) {

    }

    func updateBBCUserLabels(_ user: BBCUser) {

    }

    func userStateChange() {
    }

    func setDestination(_ site: Destination) {
        
    }

    func setProducer(_ site: Producer) {

    }

    func enable() {

    }

    func disable() {

    }

    func start() {

    }

    func clearMedia() {

    }

    func liveMediaUpdate(_ newMedia: Media, newPosition: UInt64, oldPosition: UInt64) {

    }

    func liveEnrichmentFailed() {

    }

    func setBroker(broker: Broker) {

    }

    func getDeviceID() -> String? {
        return "testDevice"
    }

    func avUserActionEvent(actionType: String, actionName: String, position: UInt64, eventLabels: [String : String]?) {

    }

    func appForegrounded() {

    }

    func appBackgrounded() {

    }

    func setPlayerName(_ name: String) {

    }

    func setPlayerVersion(_ version: String) {

    }

    func setPlayerIsPopped(_ popped: Bool) {

    }

    func setPlayerWindowState(_ state: WindowState) {

    }

    func setPlayerVolume(_ volume: Int) {

    }

    func setPlayerIsSubtitled(_ subtitled: Bool) {

    }

    func setMedia(_ media: Media) {

    }

    func setMediaLength(_ length: UInt64) {

    }

    func setMediaBitrate(_ bitrate: UInt64) {

    }

    func setMediaCodec(_ codec: String) {

    }

    func setMediaCDN(_ cdn: String) {

    }

    func avPlayEvent(at position: UInt64, eventLabels: [String : String]?) {

    }

    func avPauseEvent(at position: UInt64, eventLabels: [String : String]?) {

    }

    func avBufferEvent(at position: UInt64, eventLabels: [String : String]?) {

    }

    func avEndEvent(at position: UInt64, eventLabels: [String : String]?) {

    }

    func avRewindEvent(at position: UInt64, rate: UInt64, eventLabels: [String : String]?) {

    }

    func avFastForwardEvent(at position: UInt64, rate: UInt64, eventLabels: [String : String]?) {

    }

    func avSeekEvent(at position: UInt64, eventLabels: [String : String]?) {

    }

    func setCacheMode(_ cacheMode: EchoCacheMode) {

    }

    func getCacheMode() -> EchoCacheMode {
        return .all
    }

    func flushCache() {

    }

    func setContentLanguage(_ language: String) {

    }

    func setCounterName(_ counterName: String) {

    }

    func setBBCUser(_ user: BBCUser) {

    }

    func addManagedLabel(_ label: ManagedLabel, value: String) {

    }

    func addLabels(_ labels: [String : String]) {

    }

    func addLabel(_ key: String, value: String) {

    }

    func removeLabels(_ labels: [String]) {

    }

    func removeLabel(_ key: String) {

    }

    func setTraceID(_ trace: String) {

    }

    func viewEvent(counterName: String, eventLabels: [String : String]?) {

    }

    func userActionEvent(actionType: String, actionName: String, eventLabels: [String : String]?) {

    }

    func errorEvent(_ error: String, eventLabels: [String : String]?) {

    }


}
