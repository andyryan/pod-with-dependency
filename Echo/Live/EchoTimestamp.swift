import Foundation

@objc public class EchoTimestamp: NSObject {

    @objc internal var currentTimestamp: TimeInterval
    @objc internal var liveEdgeTimestamp: TimeInterval

    @objc public init(currentTimestamp: TimeInterval, liveEdgeTimestamp: TimeInterval) {
        self.currentTimestamp = currentTimestamp
        self.liveEdgeTimestamp = liveEdgeTimestamp
    }

}
