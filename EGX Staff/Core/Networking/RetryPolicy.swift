import Foundation

struct RetryPolicy: Sendable, Equatable {
    let maxRetries: Int
    let initialDelay: TimeInterval
    let backoffMultiplier: Double
    let maxDelay: TimeInterval

    static let none = RetryPolicy(
        maxRetries: 0,
        initialDelay: 0,
        backoffMultiplier: 1,
        maxDelay: 0
    )

    static let `default` = RetryPolicy(
        maxRetries: 2,
        initialDelay: 0.5,
        backoffMultiplier: 2.0,
        maxDelay: 4.0
    )

    func delay(forAttempt attempt: Int) -> TimeInterval {
        let raw = initialDelay * pow(backoffMultiplier, Double(attempt))
        return min(raw, maxDelay)
    }

    static func isRetryable(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .networkConnectionLost,
                 .notConnectedToInternet,
                 .dnsLookupFailed,
                 .cannotFindHost,
                 .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        if let failure = error as? Failure {
            switch failure.type {
            case .timeout, .noConnection, .network:
                return true
            case .server where (failure.statusCode ?? 0) >= 500:
                return true
            default:
                return false
            }
        }
        return false
    }
}

struct RequestTimeout: Sendable, Equatable, Hashable {
    let request: TimeInterval
    let resource: TimeInterval

    static let `default` = RequestTimeout(request: 20, resource: 35)
    static let short     = RequestTimeout(request: 8,  resource: 12)
    static let long      = RequestTimeout(request: 30, resource: 90)
}
