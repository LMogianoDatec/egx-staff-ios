import Foundation
import Observation

enum Route: Hashable {
    case sessions
    case scanner(sessionId: String, eventId: String)
}

@MainActor
@Observable
final class AppRouter {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
