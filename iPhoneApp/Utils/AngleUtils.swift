import SwiftUI

/// Convert a sensor integer output to an angle.
/// The sesnor module returns values between 0 and 4095. Convert this value to an angle.
///
/// In addition to the value being scaled, it is adjusted by 90 degrees. So, when the sensor is rotated 90 degrees (sensor value of ~1060), 0 is returned since the arm is straight.
/// Implementation explanation:
/// The sesnor's output 0 is really ~10 degrees. The sensor's output 4095 is ~300 degrees (not 360).
/// When the angle sensor is rotated 90 degrees and powered by 5W+ wall charger, it returns roughly 1060. The value returned will usually be lower if less power is supplied, so this function would not apply.
/// Note:
/// The angle returned is an approximation. The actual angle may be slightly off (likely <3 degrees)
/// - Parameters:
///  - integer: the output of the sensor (0 to 4095)
/// - Returns: the ceonverted angle (capped between -45 and 45 degrees)
func intToAngle(integer: Int) -> Int {
    if(integer > 1910) {
        return -45
    }
    if(integer < 410) {
        return 45
    }
    let zeroed = -(integer - 1060)
    let angle = Int(Double(zeroed) / 14)
    return angle
}

/// Determine the color of the arm section based on its angle. If it's less than the warning angle, green; if it's past the warning angle but less than the failure angle, orange; and if it's past the failure angle, red.
/// - Returns: RED, ORANGE, or GREEN, which are instances of Color
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
