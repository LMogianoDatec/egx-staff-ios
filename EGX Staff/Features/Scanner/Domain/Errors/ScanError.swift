import Foundation

enum ScanError: Error, Equatable {
    case invalidFormat
    case cameraUnavailable
    case cameraDenied
}

enum ScannerDomain {
    static let value = "scanner"
}
