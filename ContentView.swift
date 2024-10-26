import SwiftUI
import Foundation
import Combine

let DEFAULT_WARNING_ANGLE: Int = 10
let DEFAULT_FAILURE_ANGLE: Int = 15
// How long to wait (in seconds) for http response before timing out
let FETCH_TIMEOUT: Double = 0.5
// Longest time (seconds) allowed between successful http calls.
let MAX_FETCH_INTERVAL: Double = 3.0

// URLs to getting the angles from the controller
let lowerArmUrl = "http://192.168.4.1/lowerArmAngle"
let upperArmUrl = "http://192.168.4.1/upperArmAngle"

struct ArmPosition {
    public var upperArmAngle: Int = 0
    public var lowerArmAngle: Int = 0
    
    // Return whether the angles of the arms are within some degrees of 0
    func anglesAreWithin(maxDifference: Int) -> Bool {
        // Only check upper arm (for mechanical testing purposes)
        return upperArmAngle > -maxDifference && upperArmAngle < maxDifference
//        return lowerArmAngle > -maxDifference && lowerArmAngle < maxDifference && upperArmAngle > -maxDifference && upperArmAngle < maxDifference
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

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

struct ContentView: View {
    @State private var upperArmAngle = Int(0)
    @State private var lowerArmAngle = Int(0)
    // Record the offset of angle from 0 (allows user to "zero" device)
    @State private var upperArmOffset = Int(0)
    @State private var lowerArmOffset = Int(0)
    // Keep track of the most recent successful arm angle fetches.
    @State private var timePreviousSuccessfulFetches = Date()
    @State private var showBadConnectionWarning = false
    @State private var badConnectionToggle = true
    @State private var timer: AnyCancellable?
    @State private var warningAngleInput = String(DEFAULT_WARNING_ANGLE)
    @State private var failureAngleInput = String(DEFAULT_FAILURE_ANGLE)
    @State private var warningAngle = Int(DEFAULT_WARNING_ANGLE);
    @State private var failureAngle = Int(DEFAULT_FAILURE_ANGLE);
    
    // Coordinates of the arm
    let shoulderCoords = CGPoint(x: 70.0, y: 100.0)
    @State private var elbowCoords = CGPoint(x: 120.0, y: 100.0)
    @State private var wristCoords = CGPoint(x: 170.0, y: 100.0)
    
    @State private var attemptingStart = false
    @State private var attemptActive = false
    @State private var attemptTimer = 0
    @State private var attempt : Attempt? = nil
    
    // Round int to nearest 5 (thanks chat GPT)
    func roundToNearestN(_ number: Int, n: Int = 1) -> Int {
        if(n == 1) {
            return number
        }
        return n * Int(round(Double(number) / Double(n)))
    }
    
    // Determine what color the arm should be based on the
    // angle its bent
    func getColor(_ angle: Int) -> Color {
        let angleFromZero = abs(angle);
        if angleFromZero >= failureAngle {
            return .red
        } else if angleFromZero >= warningAngle {
            return Color(red: 210/255, green: 95/255, blue: 25/255)
        } else {
            return Color(red: 0/255, green: 120/255, blue: 0/255)
        }
    }
    
    // Convert starting coords and angle to new coords
    func getLineCoords(startX: Float, startY: Float, angle: Int, length: Float) -> CGPoint {
        
        // Convert angle to radians
        let angleInRadians = Float(angle) * Float.pi / 180.0
        // Calculate the change in x and y to next point
        let deltaX = length * cos(angleInRadians)
        let deltaY = length * sin(angleInRadians)
        return CGPoint(x: CGFloat(startX + deltaX), y: CGFloat(startY + deltaY))
    }
    
    // Convert CGPoint to a string
    func CGPointToString(point: CGPoint) -> String {
        return "(\(point.x), \(point.y))"
    }
    
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
        if(integer >= 1180) {
            let zeroed = -(integer - 1180)
            let angle = Int(Double(zeroed) / 17.111)
            return angle;
        }
        let zeroed = -(integer - 1180)
        let angle = Int(Double(zeroed) / 16.222)
        return angle
    }
    
    // Get the sensor angles by sending an http request to the
    // microcontroller.
    func fetchAngles() async {
        // When slow/no connection, there is a lot of time between the two
        // http requests. We use temp variables so that the state upper and
        // lower arm angles are updated at the same time.
        var tempUpperArmAngle = 0
        var tempLowerArmAngle = 0
        // Fetch the angles
        tempUpperArmAngle = await fetchAngle(url: upperArmUrl)
        tempLowerArmAngle = await fetchAngle(url: lowerArmUrl)
        // Convert the angles. The angles are given -1, or 0 - 4095.
        // If -1, it's an error. Otherwise, convert the value to a 0 - 45
        // degree angle.
        if(tempUpperArmAngle == -1 || tempLowerArmAngle == -1) {
            showBadConnectionWarning = true
//            print("bad connection")
            // See if too much time passed since last successful fetch
            if(Date().timeIntervalSince(timePreviousSuccessfulFetches) > MAX_FETCH_INTERVAL) {
//                print("Too much time passed since last successful fetch.")
                self.attemptEnd()
            }
        }
        else {
            showBadConnectionWarning = false
            timePreviousSuccessfulFetches = Date()
            // Scale the angles
            upperArmAngle = roundToNearestN(intToAngle(integer: tempUpperArmAngle))
            lowerArmAngle = roundToNearestN(intToAngle(integer: tempLowerArmAngle))
        }
        // Find the coordinates of the elbow based on the angle
        elbowCoords = getLineCoords(startX: Float(shoulderCoords.x), startY: Float(shoulderCoords.y), angle: upperArmAngle + upperArmOffset, length: 50)
        // Find the coordinates of the wrist based on the angle
        wristCoords = getLineCoords(startX: Float(elbowCoords.x), startY: Float(elbowCoords.y), angle: lowerArmAngle + lowerArmOffset, length: 50)
    }
    
    // Whatever the current angle of the sensor is, make this 0 degrees
    func zeroSensors() {
        upperArmOffset = -upperArmAngle
        lowerArmOffset = -lowerArmAngle
    }
    
    // Fetch to get angle. Return the angle.
    // If there's a connection issue or parsing error, return -1.
    // Any value that's not -1 can be considered a valid output.
    func fetchAngle(url: String) async -> Int {
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = FETCH_TIMEOUT
        config.timeoutIntervalForResource = FETCH_TIMEOUT
        let session = URLSession(configuration: config)
        var angle = 0
        guard let url = URL(string: url) else { return 0 }
        do {
            let (data, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                // Get the angle
                let result = String(data: data, encoding: .utf8) ?? "-1"
                angle = Int(result) ?? -1
            }
        } catch {
//            print("Error: \(error.localizedDescription)")
            return -1
        }
        return angle
    }
    
    // Set the warning angle.
    // If the failure angle is lower, it the same
    func setWarningAngle(angle: Int) {
        if(angle >= failureAngle) {
            failureAngle = angle
        }
        warningAngle = angle
    }
    
    // Set the failure angle.
    // If the warning angle is higher, make it the same
    func setFailureAngle(angle: Int) {
        if(angle <= warningAngle) {
            warningAngle = angle
            // If warning angle is now less than 0, make it zero
            if (warningAngle < 0) {
                warningAngle = 0
            }
        }
        failureAngle = angle
    }
    
    // Provide two points and the context of a canvas to draw that line on the
    // canvas.
    func drawLine (from: CGPoint, to: CGPoint, context: GraphicsContext, color: Color = .gray) {
        // Draw the body
        let linePath = Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        context.stroke(linePath,
            with:
                .color(color),
                       style: StrokeStyle(lineWidth: 10, lineCap: .round))
    }
    
    func attemptStart () {
        // If bad connection, don't start
        if(showBadConnectionWarning) {
            return
        }
        var armPosition = ArmPosition ()
        armPosition.lowerArmAngle = lowerArmAngle + lowerArmOffset
        armPosition.upperArmAngle = upperArmAngle + upperArmOffset
        attemptTimer = 0
        // Try starting an attempt. If it starts, set some variables
        if (attempt?.startAttempt(armPosition: armPosition) != nil) {
            attemptingStart = false
            attemptActive = true
        }
    }
    
    func attemptContinue () {
        var armPosition = ArmPosition ()
        armPosition.lowerArmAngle = lowerArmAngle + lowerArmOffset
        armPosition.upperArmAngle = upperArmAngle + upperArmOffset
        
        // If there's no active attempt
        if (attemptActive == false) {
            return
        }
        // Get the time since attempt started
        let time = attempt?.continueAttempt(armPosition: armPosition)
        if(time == nil) {
            return
        }
        // If attempt is done (angle reached failure)
        if(time == 0) {
            attemptEnd()
            return
        }
        // Otherwise, there's an attempt still going
        self.attemptTimer = time ?? 0
    }
    
    func attemptEnd () {
        if(!attemptActive) {
            return
        }
        self.attemptTimer = self.attempt?.endAttempt() ?? 0
        attemptActive = false
    }
    
    var body: some View {
        VStack {

            // Dropdown selection for warning and failure angles
            Text(msToFormattedString(ms: attemptTimer))
                .frame(width: 140, alignment: .leading)
                .font(.title2)
                .bold()
            
            // Two side by size containers
            HStack {
                VStack (alignment: .leading) {
                    Button (action: {
                        attempt = Attempt(warningAngle: warningAngle, failureAngle: failureAngle)
                        attemptActive = false
                        attemptingStart = true
                        attemptTimer = 0
                    }) {
                        Text("Start")
                            .padding(3)
                    }
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(5)
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.yellow)
                        TextField("Warning angle", text: $warningAngleInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(0)
                            .onChange(of: warningAngleInput) { newValue in
                                setWarningAngle(angle: Int(warningAngleInput) ?? DEFAULT_WARNING_ANGLE)
                            }
                    }
                }
                .padding(5)
                .multilineTextAlignment(.leading)
                VStack (alignment: .leading) {
                    Button (action: {
                        zeroSensors()
                    }) {
                        Text("Zero sensors")
                            .padding(3)
                    }
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(5)
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.red)
                        TextField("Fail angle", text: $failureAngleInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(0)
                            .onChange(of: failureAngleInput) { newValue in
                                setFailureAngle(angle: Int(failureAngleInput) ?? DEFAULT_FAILURE_ANGLE)
                            }
                    }
                }
                .padding(5)
                .multilineTextAlignment(.leading)
            }
            
            
            GeometryReader { geometry in
                let screenWidth = geometry.size.width;
                let originalWidth: CGFloat = 200;
                let scale = screenWidth / originalWidth;
                Canvas { context, size in
                    // Draw the head
                    let circleRect = CGRect(x: 30, y: 50, width: 40, height: 40)
                    context.fill(Path(ellipseIn: circleRect), with: .color(.gray))
                    // Draw the torso
                    drawLine(from: CGPoint(x: 50, y: 90), to: CGPoint(x: 50, y: 200), context: context)
                    // Draw the shoulders
                    drawLine(from: CGPoint(x: 30, y: 100), to: CGPoint(x: 70, y: 100), context: context)
                    // Draw the hips
                    drawLine(from: CGPoint(x: 30, y: 200), to: CGPoint(x: 70, y: 200), context: context)
                    // Draw the left leg
                    drawLine(from: CGPoint(x: 30, y: 200), to: CGPoint(x: 30, y: 280), context: context)
                    // Draw the right leg
                    drawLine(from: CGPoint(x: 70, y: 200), to: CGPoint(x: 70, y: 280), context: context)
                    // Draw the left arm
                    // Upper section
                    drawLine(from: CGPoint(x: 30, y: 100), to: CGPoint(x: 20, y: 140), context: context)
                    // Lower arm
                    drawLine(from: CGPoint(x: 20, y: 140), to: CGPoint(x: 30, y: 180), context: context)
                    
                    // Draw the arm with sensors
                    // Lower arm
                    drawLine(from: wristCoords, to: elbowCoords, context: context, color: getColor(lowerArmAngle + lowerArmOffset))
                    // Upper arm
                    drawLine(from: elbowCoords, to: shoulderCoords, context: context, color: getColor(upperArmAngle + upperArmOffset))

                    // Write the angles
                    let upperArmText = Text(verbatim: "\(upperArmAngle + upperArmOffset)°")
                        .font(.title2)
                        .foregroundColor(.white)
                    let upperArmTextPosition = CGPoint(x: 100, y: 100)
                    let lowerArmText = Text(verbatim: "\(lowerArmAngle + lowerArmOffset)°")
                        .font(.title2)
                        .foregroundColor(.white)
                    let lowerArmTextPosition = CGPoint(x: 150, y: 100)
                    context.draw(upperArmText, at: upperArmTextPosition)
                    context.draw(lowerArmText, at: lowerArmTextPosition)
                }
                .background(Color.black)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: geometry.size.width, height: 400)
                
                // Bad connection image
                if(showBadConnectionWarning) {
                    Image(systemName: "wifi.exclamationmark")
                        .resizable()
                        .position(x: 30, y: 25)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.orange)
                        .opacity(badConnectionToggle ? 1 : 0.2)
                        .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: badConnectionToggle)
                        .onAppear {
                            badConnectionToggle.toggle()
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear() {
            // Set a timer to fetch the angles every 0.1 seconds
            timer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    Task {
                        await fetchAngles()
                        if(attemptingStart) {
                            attemptStart()
                        }
                        else if(attemptActive) {
                            attemptContinue()
                        }
                    }
                }
        }
        .onDisappear() {
            timer?.cancel()
            timer = nil
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}
