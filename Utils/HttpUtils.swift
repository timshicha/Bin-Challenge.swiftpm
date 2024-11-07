import SwiftUI


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
        return -1
    }
    return angle
}
