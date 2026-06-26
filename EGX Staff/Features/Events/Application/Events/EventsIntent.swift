import Foundation

enum EventsIntent {
    case appeared
    case refresh
    case retry
    case queryChanged(String)
    case selectEvent(String)
}
