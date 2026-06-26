import SwiftUI

struct EventsView: View {
    @State private var viewModel: EventsViewModel
    @State private var showingSignOutConfirmation = false
    @Environment(AppRouter.self) private var router
    let onSignOut: () -> Void

    init(onSignOut: @escaping () -> Void) {
        self._viewModel = State(initialValue: sl())
        self.onSignOut = onSignOut
    }

    init(viewModel: EventsViewModel, onSignOut: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onSignOut = onSignOut
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ZStack {
                Color.egxBackground.ignoresSafeArea()
                content
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .sessions:
                    SessionsView(eventsViewModel: viewModel, onSignOut: onSignOut)
                        .enableInteractivePopGesture()
                case .scanner(let sessionId, let eventId):
                    ScannerView(sessionId: sessionId, eventId: eventId)
                        .toolbar(.hidden, for: .navigationBar)
                        .enableInteractivePopGesture()
                }
            }
            .alert("¿Cerrar sesión?", isPresented: $showingSignOutConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) {
                    Haptics.warning()
                    onSignOut()
                }
            } message: {
                Text("Tendrás que volver a iniciar sesión.")
            }
        }
        .task { viewModel.handle(.appeared) }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                EventSearchBar(text: queryBinding)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                listArea
                    .padding(.top, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var listArea: some View {
        if !viewModel.events.isEmpty {
            eventCards
        } else {
            switch viewModel.status {
            case .idle, .loading:
                loadingState.frame(maxWidth: .infinity).padding(.top, 60)
            case .failure:
                errorState.frame(maxWidth: .infinity).padding(.top, 40)
            case .loaded:
                emptyState.frame(maxWidth: .infinity).padding(.top, 40)
            }
        }
    }

    @ViewBuilder
    private var eventCards: some View {
        if viewModel.hasNoSearchResults {
            noResultsState
        } else {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.filteredEvents) { event in
                    EventCardView(
                        event: event,
                        onOpen: {
                            Haptics.light()
                            viewModel.handle(.selectEvent(event.id))
                            router.push(.sessions)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SELECCIONA UN EVENTO")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.egxBlue)
                Text("Eventos")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(Color.egxText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Haptics.light()
                showingSignOutConfirmation = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.forward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.egxTextSecondary)
                    .frame(width: 44, height: 44)
                    .glassSurface(in: Circle())
            }
            .buttonStyle(StaticButtonStyle())
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.egxBlue)
            Text("Cargando eventos…")
                .font(.system(size: 14))
                .foregroundStyle(Color.egxTextSecondary)
        }
    }

    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(Color.egxTextTertiary)
            Text(viewModel.errorMessage ?? "No pudimos cargar los eventos")
                .font(.system(size: 15))
                .foregroundStyle(Color.egxTextSecondary)
                .multilineTextAlignment(.center)
            Button("Reintentar") {
                Haptics.light()
                viewModel.handle(.retry)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.egxBlue)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("GeniousSad")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

            Text("Sin eventos disponibles")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.egxText)

            Text("Lo sentimos, no tienes eventos asignados por ahora.")
                .font(.system(size: 15))
                .foregroundStyle(Color.egxTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Color.egxTextTertiary)
            Text("Sin resultados para \"\(viewModel.query)\"")
                .font(.system(size: 15))
                .foregroundStyle(Color.egxTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private var queryBinding: Binding<String> {
        Binding(
            get: { viewModel.query },
            set: { viewModel.handle(.queryChanged($0)) }
        )
    }
}

/// Button style with no press animation (no fade/scale on tap).
private struct StaticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#if DEBUG
#Preview("Eventos") {
    let vm = EventsViewModel(
        fetchEvents: FetchAssignedEventsUseCase(repository: PreviewEventsRepository()),
        logger: SilentLogger()
    )
    return EventsView(viewModel: vm, onSignOut: {})
        .environment(AppRouter())
}

private final class PreviewEventsRepository: EventsRepository, @unchecked Sendable {
    func fetchAssignedEvents() async throws -> [Event] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return EventsMockData.assignedEvents.map { $0.toDomain() }
    }
}
#endif
