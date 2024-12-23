import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @State private var upperArmAngle = Int(0)
    @State private var lowerArmAngle = Int(0)
    /// Natural offset from 0 degrees of the upper arm (used for "zeroing" the sensor)
    @State private var upperArmOffset = Int(0)
    /// Natural offset from 0 degrees of the lower arm (used for "zeroing" the sensor)
    @State private var lowerArmOffset = Int(0)
    @State private var timePreviousSuccessfulFetches = Date()
    @State private var showBadConnectionWarning = false
    @State private var badConnectionToggle = true
    /// Timer for the attempt
    @State private var timer: AnyCancellable?
    /// What is currently in the warning angle input field
    @State private var warningAngleInput = String(DEFAULT_WARNING_ANGLE)
    /// What is currently in the failure angle input field
    @State private var failureAngleInput = String(DEFAULT_FAILURE_ANGLE)
    @State private var warningAngle = Int(DEFAULT_WARNING_ANGLE);
    @State private var failureAngle = Int(DEFAULT_FAILURE_ANGLE);
    /// Coordinates of where the upper arm begins
    let shoulderCoords = CGPoint(x: 87.0, y: 89.0)
    /// Coordinates of where the upper arm ends and lower arm begins
    @State private var elbowCoords = CGPoint(x: 137.0, y: 89.0)
    /// Coordinates of where the lower arm ends
    @State private var wristCoords = CGPoint(x: 187.0, y: 89.0)
    /// Whether the user is attempting to start another attempt
    @State private var attemptingStart = false
    /// Whether the current attempt is active
    @State private var attemptActive = false
    @State private var showTimer = true
    /// Milliseconds since the attempt was started
    @State private var attemptTimer = 0
    /// Stores basic info about an attempt
    @State private var attempt : Attempt? = nil
    
    // Get the sensor angles by sending an http request to the
    // microcontroller.
    func fetchAngles() async {
        // When slow/no connection, there is a lot of time between the two
        // http requests. We use temp variables so that the state upper and
        // lower arm angles are updated at the same time.
        var tempUpperArmAngle = 0
        var tempLowerArmAngle = 0
        // Fetch the angles
        tempUpperArmAngle = await fetchAngle(url: UPPER_ARM_URL)
        tempLowerArmAngle = await fetchAngle(url: LOWER_ARM_URL)
        // Convert the angles. The angles are given -1, or 0 - 4095.
        // If -1, it's an error. Otherwise, convert the value to a 0 - 45
        // degree angle.
        if(tempUpperArmAngle == -1 || tempLowerArmAngle == -1) {
            showBadConnectionWarning = true
            // See if too much time passed since last successful fetch
            if(Date().timeIntervalSince(timePreviousSuccessfulFetches) > MAX_FETCH_INTERVAL) {
                self.attemptEnd()
            }
        }
        else {
            showBadConnectionWarning = false
            timePreviousSuccessfulFetches = Date()
            // Scale the angles
            upperArmAngle = -roundToNearestN(number: intToAngle(integer: tempUpperArmAngle))
            lowerArmAngle = -roundToNearestN(number: intToAngle(integer: tempLowerArmAngle))
        }
        // Find the coordinates of the elbow based on the angle
        elbowCoords = getNextCoords(point: shoulderCoords, angle: upperArmAngle + upperArmOffset, length: 50)
        // Find the coordinates of the wrist based on the angle
        wristCoords = getNextCoords(point: shoulderCoords, angle: lowerArmAngle + lowerArmOffset, length: 50)
    }
    
    // "Zero" the sensors, i.e., adjust current position to be read as 0 degrees
    func zeroSensors() {
        upperArmOffset = -upperArmAngle
        lowerArmOffset = -lowerArmAngle
    }
    
    func setWarningAngle(angle: Int) {
        if(angle >= failureAngle) {
            failureAngle = angle
        }
        warningAngle = angle
    }
    
    func setFailureAngle(angle: Int) {
        if(angle <= warningAngle) {
            warningAngle = angle
            if (warningAngle < 0) {
                warningAngle = 0
            }
        }
        failureAngle = angle
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
            
            HStack {
                // Start button
                Button (action: {
                    attempt = Attempt(warningAngle: warningAngle, failureAngle: failureAngle)
                    attemptActive = false
                    attemptingStart = true
                    attemptTimer = 0
                }) {
                    Text("Start")
                        .padding(10)
                }
                .foregroundColor(Color.white)
                .background(Color.green)
                .cornerRadius(5)
                
                // Zero sensors button
                Button (action: {
                    zeroSensors()
                }) {
                    Text("Zero sensors")
                        .padding(10)
                }
                .foregroundColor(Color.white)
                .background(Color.green)
                .cornerRadius(5)
                
                // Reset button
                Button (action: {
                    attemptTimer = 0
                    upperArmOffset = 0
                    lowerArmOffset = 0
                }) {
                    Text("Reset")
                        .padding(10)
                }
                .foregroundColor(Color.white)
                .background(Color.green)
                .cornerRadius(5)
                
                // Timer displayal
                Text("Timer:")
                Toggle("", isOn: $showTimer)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
            }
            .padding(.top, 15)
            // Container for user warning and failure angle inputs
            HStack {
                // Warning angle input
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(ORANGE)
                    TextField("Warning angle", text: $warningAngleInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(0)
                        .onChange(of: warningAngleInput) { newValue in
                            setWarningAngle(angle: Int(warningAngleInput) ?? DEFAULT_WARNING_ANGLE)
                        }
                }
                // Failure angle input
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(RED)
                    TextField("Fail angle", text: $failureAngleInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(0)
                        .onChange(of: failureAngleInput) { newValue in
                            setFailureAngle(angle: Int(failureAngleInput) ?? DEFAULT_FAILURE_ANGLE)
                        }
                }
            }
            .padding(.horizontal, 5)

            // Either show the timer or a message
            if(showTimer) {
                Text(msToFormattedString(ms: attemptTimer))
                    .foregroundColor(attemptingStart ? .white :
                                        attemptActive ? .green: .red)
                    .foregroundColor(attemptingStart ? .white :
                                        attemptActive ? .green : .red)
                    .frame(width: 160, alignment: .leading)
                    .font(.title)
                    .bold()
            }
            else {
                Text(
                    attemptingStart ? "Waiting to start" :
                    attemptActive ? "Timer running" : "Timer stopped"
                )
                .foregroundColor(attemptingStart ? .white :
                                    attemptActive ? .green : .red)
                .font(.title)
                .bold()
            }
            
            // The canvas that draws the person and the arm
            GeometryReader { geometry in
                let screenWidth = geometry.size.width;
                let originalWidth: CGFloat = 200;
                let scale = screenWidth / originalWidth;
                Canvas { context, size in
                    // Draw the head
                    let head = CGRect(x: 35, y: 42, width: 30, height: 30)
                    context.fill(Path(ellipseIn: head), with: .color(.gray))
                    
                    // Draw the shoulders (horizontal capsule)
                    let shouldersCapsule = CGRect(x: 4, y: 80, width: 92, height: 18)
                    let shouldersPath = Path(roundedRect: shouldersCapsule, cornerRadius: 10)
                    context.fill(shouldersPath, with: .color(.gray))
                    
                    // Draw the torso
                    let torsoPath = Path(CGRect(x: 25, y: 80, width: 50, height: 100))
                    context.fill(torsoPath, with: .color(.gray))
                    
                    // Draw the left arm
                    let leftArmCapsule = CGRect(x: 4, y: 80, width: 18, height: 100)
                    let leftArmPath = Path(roundedRect: leftArmCapsule, cornerRadius: 10)
                    context.fill(leftArmPath, with: .color(.gray))
                    
                    // Draw the left leg
                    let leftLegCapsule = CGRect(x: 25, y: 170, width: 20, height: 100)
                    let leftLegPath = Path(roundedRect: leftLegCapsule, cornerRadius: 10)
                    context.fill(leftLegPath, with: .color(.gray))
                    
                    // Draw the right leg
                    let rightLegCapsule = CGRect(x: 55, y: 170, width: 20, height: 100)
                    let rightLegPath = Path(roundedRect: rightLegCapsule, cornerRadius: 10)
                    context.fill(rightLegPath, with: .color(.gray))
                    
                                                            
                    // Draw the lower arm
                    let lowerArmStart = CGPoint(x: elbowCoords.x, y: elbowCoords.y)
                    let lowerArmEnd = CGPoint(x: wristCoords.x, y: wristCoords.y)
                    var lowerArmPath = Path()
                    lowerArmPath.move(to: lowerArmStart)
                    lowerArmPath.addLine(to: lowerArmEnd)
                    context.stroke(lowerArmPath,
                        with:
                            .color(getColor(
                                angle: lowerArmAngle + lowerArmOffset,
                                warningAngle: warningAngle,
                                failureAngle: failureAngle
                                )),
                        style: StrokeStyle(lineWidth: 18.0, lineCap: .round))
                    
                    // Draw the upper arm
                    let upperArmStart = CGPoint(x: shoulderCoords.x, y: shoulderCoords.y)
                    let upperArmEnd = CGPoint(x: elbowCoords.x, y: elbowCoords.y)
                    var upperArmPath = Path()
                    upperArmPath.move(to: upperArmStart)
                    upperArmPath.addLine(to: upperArmEnd)
                    context.stroke(upperArmPath,
                        with:
                            .color(getColor(
                                angle: upperArmAngle + upperArmOffset,
                                warningAngle: warningAngle,
                                failureAngle: failureAngle
                                )),
                            style: StrokeStyle(lineWidth: 18.0, lineCap: .round))

                    // Write the angles
                    let upperArmText = Text(verbatim: "\(-(upperArmAngle + upperArmOffset))°")
                        .font(.title3)
                        .foregroundColor(.white)
                    let upperArmTextPosition = CGPoint(x: 115, y: 89)
                    let lowerArmText = Text(verbatim: "\(-(lowerArmAngle + lowerArmOffset))°")
                        .font(.title3)
                        .foregroundColor(.white)
                    let lowerArmTextPosition = CGPoint(x: 160, y: 89)
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
