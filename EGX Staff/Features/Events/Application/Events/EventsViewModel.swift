import Foundation
import Observation

@MainActor
@Observable
final class EventsViewModel {
    // Propiedades directas — @Observable trackea cada una de forma independiente.
    // SessionsView sólo observa `events`; cambios en `status` no la re-renderizan.
    private(set) var events: [Event] = []
    private(set) var status: Status = .idle
    private(set) var isRefreshing: Bool = false
    private(set) var selectedEventId: String? = nil
    var query: String = ""

    var selectedEvent: Event? { events.first { $0.id == selectedEventId } }

    enum Status: Equatable {
        case idle, loading, loaded
        case failure(String)
    }

    // MARK: - Computed

    var isLoading: Bool { status == .loading }
    var errorMessage: String? { if case .failure(let msg) = status { return msg } else { return nil } }

    var filteredEvents: [Event] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return events }
        return events.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    var hasNoSearchResults: Bool {
        status == .loaded && !events.isEmpty && filteredEvents.isEmpty
    }

    // MARK: - Init

    private let fetchEvents: FetchAssignedEventsUseCase
    private let logger: LoggerService

    init(fetchEvents: FetchAssignedEventsUseCase, logger: LoggerService) {
        self.fetchEvents = fetchEvents
        self.logger = logger
        observeSignOut()
    }

    // Observe global sign-out to clear in-memory state (events, selection, query)
    @ObservationIgnored
    nonisolated(unsafe) private var signOutObserver: NSObjectProtocol?

    private func observeSignOut() {
        signOutObserver = NotificationCenter.default.addObserver(
            forName: .egxUserSignedOut,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearStateAfterSignOut()
            }
        }
    }

    deinit {
        if let obs = signOutObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func clearStateAfterSignOut() {
        events = []
        selectedEventId = nil
        status = .idle
        query = ""
        isRefreshing = false
    }

    // MARK: - Intents

    func handle(_ intent: EventsIntent) {
        switch intent {
        case .appeared:
            if status == .idle { Task { await load() } }
        case .refresh, .retry:
            Task { await load() }
        case .queryChanged(let value):
            query = value
        case .selectEvent(let id):
            selectedEventId = id
        }
    }

    func refresh() async {
        isRefreshing = true
        await load()
        isRefreshing = false
    }

    // MARK: - Private

    private func load() async {
        guard status != .loading else { return }
        status = .loading
        do {
            let result = try await fetchEvents()
            events = result
            status = .loaded
        } catch {
            let failure = Failure.map(error, domain: EventsDomain.value)
            if failure.type == .cancelled {
                status = events.isEmpty ? .idle : .loaded
                return
            }
            logger.error("Fetch eventos falló: \(failure.message)")
            status = .failure(failure.message)
        }
    }
}

#if DEBUG
extension EventsViewModel {
    func _previewSeed(events: [Event], status: Status = .loaded) {
        self.events = events
        self.status = status
    }
}
#endif
