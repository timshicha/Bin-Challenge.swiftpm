import SwiftUI

/// Tool that converts milliseconds into other time formats.
///
/// Functions:
/// - *setTime(milliseconds)*
/// - *getMinutes()*
/// - *getSeconds()*
/// - *getMilliseconds()*
/// - *getTimeAsString()*
struct TimerTool {
    private var minutes: Int = 0
    private var seconds: Int = 0
    private var milliseconds: Int = 0
    
    /// Provide an optional time in milliseconds.
    /// The milliseconds will be converted and stored as minutes, seconds, and milliseconds.
    /// - Parameters:
    ///  - milliseconds (optional)
    init(milliseconds: Int = 0) {
        setTime(milliseconds: milliseconds)
    }
    
    /// Provide a time in milliseconds.
    /// The milliseconds will be converted and stored as minutes, seconds, and milliseconds.
    /// - Parameters:
    ///  - milliseconds
    mutating func setTime(milliseconds: Int) {
        var ms = milliseconds
        self.minutes = Int(floor(Double(ms) / 60000.0))
        ms -= self.minutes * 60000
        self.seconds = Int(floor(Double(ms) / 1000.0))
        ms -= self.seconds * 1000
        self.milliseconds = Int(ms)
    }
    
    /// Get the number of minutes.
    /// - Returns: The number of minutes
    func getMinutes () -> Int {
        return self.minutes
    }
    
    /// Get the number of seconds.
    /// - Returns: The number of seconds
    func getSeconds () -> Int {
        return self.seconds
    }
    
    /// Get the number of milliseconds.
    /// - Returns: The number of milliseconds
    func getMilliseconds () -> Int {
        return self.milliseconds
    }
    
    /// Get the time as a string in format "MM:SS.mmm".
    /// Example: "1.32.007"
    /// - Returns: The time as a string
    func getTimeAsString () -> String {
        let minutes = String(self.minutes)
        var seconds = String(self.seconds)
        var milliseconds = String(self.milliseconds)
        // Pad with 0's where needed...
        // Example: 3:5.123 -> 3:05.123
        if(self.seconds < 10) {
            seconds = "0\(seconds)"
        }
        if(self.milliseconds < 100) {
            // Example: 3:05.2 -> 3:05.002
            if(self.milliseconds < 10) {
                milliseconds = "00\(milliseconds)"
            }
            // Example: 3:05.12 -> 3:05.012
            else {
                milliseconds = "0\(milliseconds)"
            }
        }
        return "\(minutes):\(seconds).\(milliseconds)"
    }
}
