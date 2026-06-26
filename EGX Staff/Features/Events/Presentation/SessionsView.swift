import SwiftUI

struct SessionsView: View {
    let eventsViewModel: EventsViewModel
    let onSignOut: () -> Void
    @Environment(AppRouter.self) private var router
    @State private var showingSignOutConfirmation = false

    private var event: Event? { eventsViewModel.selectedEvent }

    var body: some View {
        ZStack {
            Color.egxBackground.ignoresSafeArea()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
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

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navRow
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 10)

                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                let sessions = event?.sessions ?? []
                if sessions.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sessions) { session in
                            SessionCard(session: session, onOpen: { open(session) })
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .padding(.bottom, 32)
        }
        .refreshable {
            await eventsViewModel.refresh()
        }
    }

    private var navRow: some View {
        HStack {
            Button {
                Haptics.light()
                router.pop()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Eventos")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.primary)
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 9)
                .clearGlassInteractive(in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                Haptics.light()
                showingSignOutConfirmation = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.forward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.egxTextSecondary)
                    .frame(width: 38, height: 38)
                    .glassSurface(in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text((event?.name ?? "").uppercased())
                .font(.system(size: 13, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.egxBlue)
                .lineLimit(1)
            Text("Sesiones")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Color.egxText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("GeniousSad")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            Text("Sin sesiones disponibles")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.egxText)
            Text("Este evento no tiene sesiones asignadas por ahora.")
                .font(.system(size: 15))
                .foregroundStyle(Color.egxTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
        }
    }

    private func open(_ session: EventSession) {
        guard session.isScannable(), let event else { return }
        Haptics.light()
        router.push(.scanner(sessionId: session.id, eventId: event.id))
    }
}

#if DEBUG
#Preview("Sesiones") {
    let vm = EventsViewModel(
        fetchEvents: FetchAssignedEventsUseCase(repository: PreviewSessionsRepository()),
        logger: SilentLogger()
    )
    NavigationStack {
        SessionsView(eventsViewModel: vm, onSignOut: {})
    }
    .environment(AppRouter())
    .task {
        vm.handle(.appeared)
        let id = EventsMockData.assignedEvents[0].toDomain().id
        vm.handle(.selectEvent(id))
    }
}

private final class PreviewSessionsRepository: EventsRepository, @unchecked Sendable {
    func fetchAssignedEvents() async throws -> [Event] {
        EventsMockData.assignedEvents.map { $0.toDomain() }
    }
}
#endif
