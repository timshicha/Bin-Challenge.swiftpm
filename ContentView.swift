import SwiftUI
import Foundation

struct ContentView: View {
    @State private var startingX = String()
    @State private var startingY = String()
    @State private var angle = String()
    @State private var length = String()
    @State private var direction = String()
    @State private var result = [Float(0.0), Float(0.0)]
    @State private var resultString = String()
    @State private var espData: String = "Loading..."
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    // Provide the starting point on the canvas and angle angle
    // of the arm. Returns where the end point is.
    // 0 degrees means parallel to the ground.
    // Direction refers to the direction the arm is facing.
    func getLineCoords(startX: Float, startY: Float, angle: Float, length: Float, direction: String) -> CGPoint {
        
        var deltaX = Float(0.0)
        var deltaY = Float(0.0)
        
        // Convert angle and direction to a radian-based value
        // on the unit circle
        var inRadians = Float(0.0)
        if(direction == "Left") {
            inRadians = Float.pi
        }
        let angleInRadians = angle * Float.pi / 180.0
        // If arm is facing right, add the angle since it adds to
        // the unit circle. If arm is facing left, subtract from the
        // unit circle so it adds elevation.
        if(direction == "Right") {
            inRadians += angleInRadians
        }
        else {
            inRadians -= angleInRadians
        }
        
        deltaX = length * cos(inRadians)
        deltaY = length * sin(inRadians)
        
        return CGPoint(x: CGFloat(startX + deltaX), y: CGFloat(startY + deltaY))
    }
    
    // Convert CGPoint to a string
    func CGPointToString(point: CGPoint) -> String {
        return "(\(point.x), \(point.y))"
    }
    
    func fetchESP32Data() {
        let url = URL(string: "http://192.168.4.1/angle")!
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response:", responseString)
                DispatchQueue.main.async {
                    self.angle = responseString
                }
            }
        }
        task.resume()
    }
    
    var body: some View {
        VStack {
            
            Text(angle)
            Button("Fetch data", action: fetchESP32Data)
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
        }
    }
}
