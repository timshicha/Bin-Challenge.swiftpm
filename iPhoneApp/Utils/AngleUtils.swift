import SwiftUI

// Microcontroller returns the value of the sensor as an int
// between 0 and 4095. Convert it to an angle between -45 and 45
// degrees.
// Notes:
// The sensor's output is not linearly proportional to the real
// angle. To minimize the error, this function uses a different
// formula for angles less than 0 degrees and above 0 degrees.
func intToAngle(integer: Int) -> Int {
    if(integer > 1910) {
        return -45
    }
    if(integer < 410) {
        return 45
    }
    if(integer >= 1060) {
        let zeroed = -(integer - 1060)
        let angle = Int(Double(zeroed) / 14.2)
        return angle
    }
    let zeroed = -(integer - 1060)
    let angle = Int(Double(zeroed) / 14)
    return angle
}

// Determine what color the arm should be based on the
// angle its bent
func getColor(angle: Int, warningAngle: Int, failureAngle: Int) -> Color {
    let angleFromZero = abs(angle);
    if angleFromZero >= failureAngle {
        return RED
    } else if angleFromZero >= warningAngle {
        return ORANGE
    } else {
        return GREEN
    }
}
