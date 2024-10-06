import SwiftUI

struct ContentView: View {
    @State private var startingX = String()
    @State private var startingY = String()
    @State private var angle = String()
    @State private var length = String()
    @State private var direction = String()
    @State private var result = [Float(0.0), Float(0.0)]
    @State private var resultString = String()
    
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
    
    var body: some View {
        VStack {
            Text("Starting X: ")
            TextField("", text: $startingX)
                .keyboardType(.decimalPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Starting Y: ")
            TextField("", text: $startingY)
                .keyboardType(.decimalPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Angle: ")
            TextField("", text: $angle)
                .keyboardType(.decimalPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Length: ")
            TextField("", text: $length)
                .keyboardType(.decimalPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Direction: ")
            Picker("", selection: $direction) {
                ForEach(["Left", "Right"], id: \.self) {
                    dir in Text(dir)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Text("End point: " + resultString)
            
            Button(action: {
                let startX = Float(startingX) ?? Float(0.0)
                let startY = Float(startingY) ?? Float(0.0)
                let angle = Float(self.angle) ?? Float(0.0)
                let length = Float(self.length) ?? Float(0.0)
                let direction = self.direction
                
                self.resultString = CGPointToString(point: getLineCoords(startX: startX, startY: startY, angle: angle, length: length, direction: direction))
            }) {
                Text("Calculate")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
