import SwiftUI
import Foundation
import Combine

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
