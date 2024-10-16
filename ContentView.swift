import SwiftUI
import Foundation
import Combine

// URLs to getting the angles from the controller
let lowerArmUrl = "http://192.168.4.1/lowerArmAngle"
let upperArmUrl = "http://192.168.4.1/upperArmAngle"

struct ContentView: View {
    @State private var upperArmAngle = Int(0)
    @State private var lowerArmAngle = Int(0)
    @State private var timer: AnyCancellable?
    @State private var warningAngle = Int(10);
    @State private var failureAngle = Int(20);
    
    // Coordinates of the arm
    let shoulderCoords = CGPoint(x: 70.0, y: 100.0)
    @State private var elbowCoords = CGPoint(x: 120.0, y: 100.0)
    @State private var wristCoords = CGPoint(x: 170.0, y: 100.0)
    
    // Round int to nearest 5 (thanks chat GPT)
    func roundToNearestFive(_ number: Int) -> Int {
        return 5 * Int(round(Double(number) / 5.0))
    }
    
    // Determine what color the arm should be based on the
    // angle its bent
    func getColor(_ angle: Int) -> Color {
        let angleFromZero = abs(angle);
        if angleFromZero >= failureAngle {
            return .red
        } else if angleFromZero >= warningAngle {
            return .orange
        } else {
            return .green
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
        // Fetch and convert the upper arm angle
        upperArmAngle = roundToNearestFive(intToAngle(integer: await fetchAngle(url: lowerArmUrl)))
        // Find the coordinates of the elbow based on the angle
        elbowCoords = getLineCoords(startX: Float(shoulderCoords.x), startY: Float(shoulderCoords.y), angle: upperArmAngle, length: 50)
        // Fetch and convert the lower arm angle
        lowerArmAngle = roundToNearestFive(intToAngle(integer: await fetchAngle(url: upperArmUrl)))
        // Find the coordinates of the wrist based on the angle
        wristCoords = getLineCoords(startX: Float(elbowCoords.x), startY: Float(elbowCoords.y), angle: lowerArmAngle, length: 50)
    }
    
    // Fetch to get angle. Return the angle
    func fetchAngle(url: String) async -> Int {
        var angle = 0
        guard let url = URL(string: url) else { return 0 }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let result = String(data: data, encoding: .utf8) {
                // Get the angle
                angle = Int(result) ?? 0
            }
        } catch {
            angle = 0
        }
        return angle
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
    
    var body: some View {
        VStack {
            
            // Dropdown selection for warning and failure angles
            Text("Upper arm")
            Menu {
                Button ("5\u{00B0}") {
                    warningAngle = 5
                }
                Button ("10\u{00B0}") {
                    warningAngle = 10
                }
                Button ("15\u{00B0}") {
                    warningAngle = 15
                }
            } label: {
                Label("Warning angle: \(warningAngle)", systemImage: "chevron.down")
            }
            Menu {
                if (warningAngle) <= 5 {
                    Button ("10\u{00B0}") {
                        failureAngle = 10
                    }
                }
                if (warningAngle) <= 10 {
                    Button ("15\u{00B0}") {
                        failureAngle = 15
                    }
                }
                if (warningAngle <= 15) {
                    Button ("20\u{00B0}") {
                        failureAngle = 20
                    }
                }
                if (warningAngle <= 20) {
                    Button ("25\u{00B0}") {
                        failureAngle = 25
                    }
                }
            } label: {
                Label("Failure angle: \(failureAngle)", systemImage: "chevron.down")
                    .foregroundColor(.red)
            }
                        
            Text("Upper arm angle: " + String(upperArmAngle))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Lower arm angle: " + String(lowerArmAngle))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GeometryReader { geometry in
                let screenWidth = geometry.size.width;
                let originalWidth: CGFloat = 200;
                let scale = screenWidth / originalWidth;
                Canvas { context, size in
                    // Drwa the head
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
                    drawLine(from: wristCoords, to: elbowCoords, context: context, color: getColor(lowerArmAngle))
                    // Upper arm
                    drawLine(from: elbowCoords, to: shoulderCoords, context: context, color: getColor(upperArmAngle))
                }
                .frame(width: 200, height: 300)
                .background(Color.white)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .edgesIgnoringSafeArea(.all)

        }
        .onAppear() {
            // Set a timer to fetch the angles every 0.1 seconds
            timer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    Task {
                        await fetchAngles()
                    }
                }
        }
        .onDisappear() {
            timer?.cancel()
            timer = nil
        }
    }
}
