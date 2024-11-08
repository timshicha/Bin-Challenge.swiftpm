import SwiftUI
import Foundation
import Combine

/// Find a set of coordinates based on another set of coordinates, and angle and distance
///
/// We know where the arm section begins and the angle of the arm. We can use these details to find where the arm section will end.
/// - Parameters:
///  - startX: The X coordinate of the known point
///  - startY: The Y coordinate of the known point
///  - angle: The angle of the arm
///  - length: The length of the arm
/// - Returns: The coordinates of the next point
func getLineCoords(startX: Float, startY: Float, angle: Int, length: Float) -> CGPoint {
    
    // Convert angle to radians
    let angleInRadians = Float(angle) * Float.pi / 180.0
    // Calculate the change in x and y to next point
    let deltaX = length * cos(angleInRadians)
    let deltaY = length * sin(angleInRadians)
    return CGPoint(x: CGFloat(startX + deltaX), y: CGFloat(startY + deltaY))
}

/// Convert CGPoint to a string
/// - Returns: String in format "(X, Y)"
func CGPointToString(point: CGPoint) -> String {
    return "(\(point.x), \(point.y))"
}

/// Provide two points and the context of a canvas to draw that line on the canvas.
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
