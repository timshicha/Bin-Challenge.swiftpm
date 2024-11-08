import SwiftUI

// Keep track of an attempt state, time, and history.
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
    
    // If the arm is in proper position (green), the attempt starts, return self.
    // Return 0 if attempt was not started.
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
    
    // Provide another arm position. If arm is in red (failure) range, stop the
    // attempt and return 0. Otherwise, return the number of milliseconds since
    // the attempt was started (timer).
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
    
    // Manually end the attempt (such as when the connection is lost)
    mutating func endAttempt() -> Int {
        let timeEnded = Date()
        let timeStarted = self.timeStarted ?? Date()
        self.timeEnded = timeEnded
        self.attemptActive = false
        print("end attempt")
        return Int(Double(timeEnded.timeIntervalSince(timeStarted)) * 1000)
    }
    
    func getHistory() -> [ArmPosition] {
        return self.history
    }
}
