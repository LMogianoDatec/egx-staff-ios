import Foundation

struct ScanResult: Equatable, Sendable {
    let outcome: AccessOutcome
    let scannedAt: Date
    let rawPayload: String
}
