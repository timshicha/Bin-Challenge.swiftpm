struct Timer {
    private var minutes: Int = 0
    private var seconds: Int = 0
    private var milliseconds: Int = 0
    
    mutating func setTime(milliseconds: Int) {
        var ms = milliseconds
        self.minutes = Int(floor(Double(ms) / 60000.0))
        ms -= self.minutes * 60000
        self.seconds = Int(floor(Double(ms) / 1000.0))
        ms -= self.seconds * 1000
        self.milliseconds = Int(ms)
    }
    
    func getMinutes () -> Int {
        return self.minutes
    }
    
    func getSeconds () -> Int {
        return self.getSeconds()
    }
    
    func getMilliseconds () -> Int {
        return self.milliseconds
    }
    
    func getTimeAsString () -> String {
        let minutes = String(self.minutes)
        var seconds = String(self.seconds)
        var milliseconds = String(self.milliseconds)
        // Pad with 0's where needed...
        // Example: 3:5.123 -> 3:05.123
        if(self.seconds < 10) {
            seconds = "0\(seconds)"
        }
        if(self.milliseconds < 100) {
            // Example: 3:05.2 -> 3:05.002
            if(self.milliseconds < 10) {
                milliseconds = "00\(milliseconds)"
            }
            // Example: 3:05.12 -> 3:05.012
            else {
                milliseconds = "0\(milliseconds)"
            }
        }
    }
}