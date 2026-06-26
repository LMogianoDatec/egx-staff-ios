import SwiftUI

struct SessionCard: View {
    let session: EventSession
    let onOpen: () -> Void

    private var state: EventSession.AccessState { session.accessState() }
    private var scannable: Bool { session.isScannable() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 0) {
                statePill
                Spacer()
                timeStack
            }

            Text(session.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.egxText)
                .lineLimit(2)

            HStack(spacing: 0) {
                if !session.accessRange.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 13))
                        Text("Validación \(session.accessRange)")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color.egxTextSecondary)
                }
                Spacer()
                goButton
            }
        }
        .padding(16)
        .background(Color.egxGroupedBG)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            Haptics.light()
            onOpen()
        }
    }

    private var statePill: some View {
        HStack(spacing: 7) {
            if state == .openNow {
                PulsingDot(color: stateColor, size: 8)
            } else {
                Circle()
                    .fill(stateColor)
                    .frame(width: 8, height: 8)
            }
            Text(stateLabel)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(stateColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(stateColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var timeStack: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(session.startTime)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.egxText)
                .monospacedDigit()
            if !session.endTime.isEmpty {
                Text("hasta \(session.endTime)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.egxTextSecondary)
            }
        }
    }

    private var goButton: some View {
        Button {
            Haptics.light()
            onOpen()
        } label: {
            Text("Ir")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(scannable ? .white : Color.egxTextTertiary)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .glassSurfaceInteractive(in: Capsule(), tint: scannable ? Color.egxBlue : nil)
        }
        .buttonStyle(.plain)
        .disabled(!scannable)
    }

    private var stateLabel: String {
        switch state {
        case .openNow:  return "ACCESO ABIERTO"
        case .upcoming: return "PRÓXIMA"
        case .closed:   return "ACCESO CERRADO"
        case .unknown:  return "DISPONIBLE"
        }
    }

    private var stateColor: Color {
        switch state {
        case .openNow:  return Color.egxSuccess
        case .upcoming: return Color.egxBlue
        case .closed:   return Color.egxTextTertiary
        case .unknown:  return Color.egxBlue
        }
    }
}

#if DEBUG
#Preview("Session Cards") {
    let now = Date()
    let sessions: [EventSession] = [
        EventSession(
            id: "1", name: "Acreditación y registro",
            start: now.addingTimeInterval(-3600), end: now.addingTimeInterval(-1800),
            accessStart: now.addingTimeInterval(-3900), accessEnd: now.addingTimeInterval(-1800)
        ),
        EventSession(
            id: "2", name: "Desayuno & Keynote de apertura",
            start: now, end: now.addingTimeInterval(5400),
            accessStart: now.addingTimeInterval(-900), accessEnd: now.addingTimeInterval(5400)
        ),
        EventSession(
            id: "3", name: "Panel: Detección y respuesta ante incidentes",
            start: now.addingTimeInterval(5400), end: now.addingTimeInterval(12600),
            accessStart: now.addingTimeInterval(4500), accessEnd: now.addingTimeInterval(12600)
        )
    ]
    return ScrollView {
        VStack(spacing: 12) {
            ForEach(sessions) { s in
                SessionCard(session: s, onOpen: {})
            }
        }
        .padding()
    }
    .background(Color.egxBackground)
}
#endif
