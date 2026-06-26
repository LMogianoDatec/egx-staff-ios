import SwiftUI

struct ResultSheetView: View {
    let result: ScanResult
    let confirm: ScannerViewModel.ConfirmPhase
    let onConfirm: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Spacer(minLength: 24)
                    icon
                    statusLabel
                    title
                    subtitle
                    Spacer(minLength: 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 26)

                Spacer()

                actionButton
            }

            closeButton
                .padding(.top, 14)
                .padding(.trailing, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationBackground { background }
    }

    // MARK: - Local phase

    private enum Phase: Equatable {
        case grantedIdle(Attendee)
        case confirming
        case registered
        case alreadyScanned
        case confirmFailure(String)
        case denied(String)
    }

    private var phase: Phase {
        switch result.outcome {
        case .denied(let reason):
            return .denied(reason.userMessage)
        case .granted(let attendee):
            switch confirm {
            case .idle:    return .grantedIdle(attendee)
            case .loading: return .confirming
            case .done(let r):
                switch r {
                case .registered:     return .registered
                case .alreadyScanned: return .alreadyScanned
                case .failure(let m): return .confirmFailure(m)
                }
            }
        }
    }

    private var isPositive: Bool {
        switch phase {
        case .grantedIdle, .confirming, .registered, .alreadyScanned: return true
        case .denied, .confirmFailure: return false
        }
    }

    // MARK: - Pieces

    private var closeButton: some View {
        Button {
            Haptics.light()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.18), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var icon: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(isPositive ? "GeniousNeutral" : "GeniousSad")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

            if case .registered = phase {
                checkBadge.offset(x: -4, y: -4)
            }
        }
    }

    private var checkBadge: some View {
        ZStack {
            Circle()
                .fill(Color.egxSuccess)
                .frame(width: 38, height: 38)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var statusLabel: some View {
        Text(statusText)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(.white.opacity(0.85))
    }

    private var statusText: String {
        switch phase {
        case .grantedIdle:    return "INVITADO ENCONTRADO"
        case .confirming:     return "CONFIRMANDO…"
        case .registered:     return "ASISTENCIA CONFIRMADA"
        case .alreadyScanned: return "YA REGISTRADO"
        case .confirmFailure: return "NO SE PUDO CONFIRMAR"
        case .denied:         return "ACCESO DENEGADO"
        }
    }

    private var title: some View {
        Text(titleText)
            .font(.system(size: 26, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
    }

    private var titleText: String {
        switch result.outcome {
        case .granted(let a): return a.fullName
        case .denied(let reason): return reason.userMessage
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if let text = subtitleText {
            Text(text)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 18)
        }
    }

    private var subtitleText: String? {
        switch phase {
        case .grantedIdle(let a):
            return [a.company.isEmpty ? nil : a.company, a.sessionName]
                .compactMap { $0 }
                .joined(separator: " · ")
                .nilIfEmpty
        case .alreadyScanned:
            return "Este invitado ya fue escaneado."
        case .confirmFailure(let m):
            return m
        case .denied:
            return "Verifica el código e inténtalo de nuevo."
        case .confirming, .registered:
            return nil
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch phase {
        case .grantedIdle:
            bandButton(title: "Confirmar asistencia", loading: false, action: onConfirm)
        case .confirming:
            bandButton(title: "Confirmar asistencia", loading: true, action: {})
        case .registered, .alreadyScanned, .confirmFailure, .denied:
            bandButton(title: "Cerrar", loading: false, action: onClose)
        }
    }

    private func bandButton(title: String, loading: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .opacity(loading ? 0 : 1)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.white.opacity(0.16))
                .overlay {
                    if loading {
                        ProgressView().progressViewStyle(.circular).tint(.white)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(loading)
    }

    // MARK: - Background

    private var background: LinearGradient {
        let colors: [Color]
        switch phase {
        case .registered:
            colors = [Color.egxSuccess, Color(hex: "#1FA34B")]
        case .alreadyScanned:
            colors = [Color(hex: "#F5A623"), Color(hex: "#D98300")]
        case .denied, .confirmFailure:
            colors = [Color.egxError, Color(hex: "#E0241B")]
        case .grantedIdle, .confirming:
            colors = [Color.egxBlue, Color.egxBlueDeep]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview("Encontrado") {
    ResultSheetView(
        result: ScanResult(
            outcome: .granted(Attendee(
                id: "1", userEventId: "ue1", fullName: "María García",
                email: "maria@empresa.com", company: "Empresa S.A.",
                idn: "idn_x", approvalStatus: "approved",
                sessionName: "Día 1", alreadyScanned: false
            )),
            scannedAt: .now, rawPayload: "preview"
        ),
        confirm: .idle,
        onConfirm: {},
        onClose: {}
    )
}

#Preview("Confirmado") {
    ResultSheetView(
        result: ScanResult(
            outcome: .granted(Attendee(
                id: "1", userEventId: "ue1", fullName: "María García",
                email: "m@e.com", company: "Empresa", idn: "idn_x",
                approvalStatus: "approved", sessionName: "Día 1", alreadyScanned: false
            )),
            scannedAt: .now, rawPayload: "preview"
        ),
        confirm: .done(.registered),
        onConfirm: {},
        onClose: {}
    )
}

#Preview("Denegado") {
    ResultSheetView(
        result: ScanResult(outcome: .denied(reason: .notFound), scannedAt: .now, rawPayload: "preview"),
        confirm: .idle,
        onConfirm: {},
        onClose: {}
    )
}
