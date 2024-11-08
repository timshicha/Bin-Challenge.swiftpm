import SwiftUI

/// Keep track of necessary variables related to an attempt and determine the state of an attempt.
///
/// Functions:
/// - *init(warningAngle, failureAngle)*
/// - *startAttempt(armPosition)*
/// - *continueAttempt(armPosition)*
/// - *endAttempt()*
struct Attempt {
    private var attemptActive: Bool
    private var timeStarted: Date?
    private var timeEnded: Date?
    private var history: [ArmPosition]
    private var warningAngle: Int
    private var failureAngle: Int
    
    init(warningAngle: Int = DEFAULT_WARNING_ANGLE,
         failureAngle: Int = DEFAULT_FAILURE_ANGLE) {
        self.attemptActive = false
        self.timeStarted = nil
        self.timeEnded = nil
        self.history = [ArmPosition] ()
        self.warningAngle = warningAngle
        self.failureAngle = failureAngle
    }
    
    /// Attempt to start at attempt. If both sections of the arm are in the green range (less than warningAngle), then the attempt will start.
    /// - Parameters:
    ///   - armPosition: The state of the current arm
    /// - Returns: Self, or nil if the attempt was not started
    mutating func startAttempt(armPosition: ArmPosition) -> Attempt? {
        // If proper position
        if (armPosition.anglesAreWithin(maxDifference: self.warningAngle)) {
            // Record this angle and return success
            self.history = [armPosition]
            self.timeStarted = Date()
            self.timeEnded = nil
            self.attemptActive = true
            return self
        }
        return nil
    }
    
    /// Attempt to continue an attempt. If a section of the arm is in the failureAngle (red) range, the attempt will end.
    /// - Parameters:
    ///  - armPosition: The state of the current arm
    /// - Returns: Milliseconds since the attempt was started, or 0 if the attemp was ended
    mutating func continueAttempt(armPosition: ArmPosition) -> Int {
        // If proper angle
        if (armPosition.anglesAreWithin(maxDifference: self.failureAngle)) {
            // Record the angle and return the time
            self.history.append(armPosition)
            return Int(Double(Date().timeIntervalSince(self.timeStarted!)) * 1000)
        }
        self.timeEnded = Date()
        self.attemptActive = false
        return 0
    }
    
    /// Manually end an attempt (such as on force end or connection loss)
    /// - Returns: Milliseconds since the attempt was started
    mutating func endAttempt() -> Int {
        let timeEnded = Date()
        let timeStarted = self.timeStarted ?? Date()
        self.timeEnded = timeEnded
        self.attemptActive = false
        return Int(Double(timeEnded.timeIntervalSince(timeStarted)) * 1000)
    }
    
    /// Get the history of the arm positions for this attempt.
    /// - Returns: History of arm positions in a list
    func getHistory() -> [ArmPosition] {
        return self.history
    }
}
