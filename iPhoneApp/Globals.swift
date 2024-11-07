import SwiftUI

let DEFAULT_WARNING_ANGLE: Int = 10
let DEFAULT_FAILURE_ANGLE: Int = 15
// How long to wait (in seconds) for http response before timing out
let FETCH_TIMEOUT: Double = 0.5
// Longest time (seconds) allowed between successful http calls.
let MAX_FETCH_INTERVAL: Double = 3.0

// URLs to getting the angles from the controller
let lowerArmUrl = "http://192.168.4.1/lowerArmAngle"
let upperArmUrl = "http://192.168.4.1/upperArmAngle"

let RED = Color(red: 145/255, green: 0/255, blue: 0/255)
let ORANGE = Color(red: 210/255, green: 95/255, blue: 25/255)
let GREEN = Color(red: 0/255, green: 120/255, blue: 0/255)
