
/// Stores the position of an arm.
///
/// Variables:
/// - *upperArmAngle*
/// - *lowerArmAngle*
/// Functions:
/// - *anglesAreWithin(maxDifference)*
struct ArmPosition {
    public var upperArmAngle: Int = 0
    public var lowerArmAngle: Int = 0
    
    /// Determine if the angles of the arm sections are within some difference of 0.
    /// - Parameters:
    ///  - maxDifference: how far the arm section angles can be away from 0
    func anglesAreWithin(maxDifference: Int) -> Bool {
        return lowerArmAngle > -maxDifference && lowerArmAngle < maxDifference && upperArmAngle > -maxDifference && upperArmAngle < maxDifference
    }
}
