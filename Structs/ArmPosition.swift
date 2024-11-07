

struct ArmPosition {
    public var upperArmAngle: Int = 0
    public var lowerArmAngle: Int = 0
    
    // Return whether the angles of the arms are within some degrees of 0
    func anglesAreWithin(maxDifference: Int) -> Bool {
        return lowerArmAngle > -maxDifference && lowerArmAngle < maxDifference && upperArmAngle > -maxDifference && upperArmAngle < maxDifference
    }
}
