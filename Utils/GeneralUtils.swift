import SwiftUI

// Hide the keyboard when the user taps away on the screen
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Round int to nearest 5 (thanks chat GPT)
func roundToNearestN(_ number: Int, n: Int = 1) -> Int {
    if(n == 1) {
        return number
    }
    return n * Int(round(Double(number) / Double(n)))
}

// Return milliseconds as string.
// Ex: 63589 -> "1:03.589
func msToFormattedString(ms: Int) -> String {
    var ms = ms
    let minutesInt = Int(floor(Double(ms) / 60000.0))
    ms -= minutesInt * 60000
    let secondsInt = Int(floor(Double(ms) / 1000.0))
    ms -= secondsInt * 1000
    let millisecondsInt = Int(ms)

    let minutes = String(minutesInt)
    var seconds = String(secondsInt)
    var milliseconds = String(millisecondsInt)
    // Pad with 0's where needed...
    // Example: 3:5.123 -> 3:05.123
    if(secondsInt < 10) {
        seconds = "0\(secondsInt)"
    }
    if(millisecondsInt < 100) {
        // Example: 3:05.2 -> 3:05.002
        if(millisecondsInt < 10) {
            milliseconds = "00\(millisecondsInt)"
        }
        // Example: 3:05.12 -> 3:05.012
        else {
            milliseconds = "0\(millisecondsInt)"
        }
    }
    return "\(minutes):\(seconds).\(milliseconds)"
}
