import Foundation

enum ScannerIntent {
    case start
    case stop
    case toggleTorch
    case qrDetected(String)
    case confirmAttendance
    case dismissResult
}
