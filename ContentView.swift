import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @State private var startingX = String()
    @State private var startingY = String()
    @State private var upperArmAngle = Int(0)
    @State private var lowerArmAngle = Int(0)
    @State private var length = String()
    @State private var result = [Float(0.0), Float(0.0)]
    @State private var resultString = String()
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var timer: AnyCancellable?
    
    @State private var warningAngle = Int(10);
    @State private var failureAngle = Int(20);
    
    
    let shoulderCoords = CGPoint(x: 25.0, y: 50.0)
    @State private var elbowCoords = CGPoint(x: 0.0, y: 0.0)
    @State private var wristCoords = CGPoint(x: 0.0, y: 0.0)
    
    // Thank you ChatGPT:
    func roundToNearestFive(_ number: Int) -> Int {
        return 5 * Int(round(Double(number) / 5.0))
    }
    
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
    
    // Provide the starting point on the canvas and angle angle
    // of the arm. Returns where the end point is.
    // 0 degrees means parallel to the ground.
    // Direction refers to the direction the arm is facing.
    func getLineCoords(startX: Float, startY: Float, angle: Int, length: Float) -> CGPoint {
        
        var deltaX = Float(0.0)
        var deltaY = Float(0.0)
        
        // Convert angle and direction to a radian-based value
        // on the unit circle
        var inRadians = Float(0.0)

        let angleInRadians = Float(angle) * Float.pi / 180.0

        inRadians += angleInRadians
        
        deltaX = length * cos(inRadians)
        deltaY = length * sin(inRadians)
        
        return CGPoint(x: CGFloat(startX + deltaX), y: CGFloat(startY + deltaY))
    }
    
    // Convert CGPoint to a string
    func CGPointToString(point: CGPoint) -> String {
        return "(\(point.x), \(point.y))"
    }
    
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
    
    func fetchAngles() {
        var url = URL(string: "http://192.168.4.1/upperArmAngle")!
        var task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response:", responseString)
                DispatchQueue.main.async {
                    let tempAngle = Int(responseString) ?? 0
                    upperArmAngle = roundToNearestFive(intToAngle(integer: tempAngle));
                    elbowCoords = getLineCoords(startX: Float(shoulderCoords.x), startY: Float(shoulderCoords.y), angle: upperArmAngle, length: 25)
//                    // Fore arm will continue where upper arm left
//                    // Make fore arm angle 0 for now
//                    wristCoords = getLineCoords(startX: Float(elbowCoords.x), startY: Float(elbowCoords.y), angle: lowerArmAngle, length: 25)
                }
            }
        }
        task.resume()
        
        url = URL(string: "http://192.168.4.1/lowerArmAngle")!
        task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response:", responseString)
                DispatchQueue.main.async {
                    let tempAngle = Int(responseString) ?? 0
                    lowerArmAngle = roundToNearestFive(intToAngle(integer: tempAngle));
                    wristCoords = getLineCoords(startX: Float(elbowCoords.x), startY: Float(elbowCoords.y), angle: lowerArmAngle, length: 25)
                }
            }
        }
        task.resume()
    }
    
    var body: some View {
        VStack {
            
            Text(String(upperArmAngle))
            Button("Fetch data", action: fetchAngles)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"),
                          message: Text(self.alertMessage),
                          dismissButton: .default(Text("OK"))
                    )
                }
            
            GeometryReader { geometry in
                
                Canvas { context, size in
                    let scale = geometry.size.width / 100
                    context.stroke(Path { _ in
                        
                        // Draw the body
                        var linePath = Path { path in
                            // Draw shoulders
                            path.move(to:CGPoint(x: shoulderCoords.x * scale, y: shoulderCoords.y * scale))
                            path.addLine(to: CGPoint(x: (shoulderCoords.x - 20) * scale, y: (shoulderCoords.y) * scale))
                            // Draw torso
                            path.move(to:CGPoint(x: (shoulderCoords.x - 10) * scale, y: (shoulderCoords.y - 5) * scale))
                            path.addLine(to: CGPoint(x: (shoulderCoords.x - 10) * scale, y: (shoulderCoords.y + 30) * scale))
                        }
                        context.stroke(linePath,
                            with:
                                .color(.gray),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        
                        // Draw the fore arm
                        linePath = Path { path in
                            path.move(to: CGPoint(x: wristCoords.x * scale, y: wristCoords.y * scale))
                            path.addLine(to: CGPoint(x: elbowCoords.x * scale, y: elbowCoords.y * scale))
                        }
                        context.stroke(linePath,
                                       with: .color(getColor(lowerArmAngle)),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        
                        // Draw the upper arm
                        linePath = Path { path in
                            path.move(to: CGPoint(x: shoulderCoords.x * scale, y: shoulderCoords.y * scale))
                            path.addLine(to: CGPoint(x: elbowCoords.x * scale, y: elbowCoords.y * scale))
                        }
                        context.stroke(linePath,
                                       with: .color(getColor(upperArmAngle)),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        
                    }, with: .color(.black), lineWidth: 5)
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
                .background(Color.white)
            }
            .edgesIgnoringSafeArea(.all)

        }
        .onAppear() {
            timer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    fetchAngles()
                }
        }
        .onDisappear() {
            timer?.cancel()
            timer = nil
        }
    }
}
