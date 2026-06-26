import SwiftUI

struct ScannerView: View {
    @State private var viewModel: ScannerViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    init(sessionId: String, eventId: String) {
        self._viewModel = State(initialValue: ScannerViewModel(
            sessionId: sessionId,
            eventId: eventId,
            checkUseCase: sl(),
            confirmUseCase: sl(),
            logger: sl(),
            camera: AVCameraController()
        ))
    }

    init(viewModel: ScannerViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.cameraPermission == .granted {
                if viewModel.scannerAvailable {
                    scannerContent
                } else {
                    ScannerUnsupportedView(onBack: { dismiss() })
                }
            } else {
                CameraPermissionView(
                    isDenied: viewModel.cameraPermission == .denied,
                    onRequest: { Task { await viewModel.requestCameraPermission() } },
                    onOpenSettings: { viewModel.openAppSettings() }
                )
            }
        }
        .task { viewModel.refreshCameraPermission() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refreshCameraPermission()
            }
        }
    }

    private var scannerContent: some View {
        glassContainer {
            scannerStack
        }
        .statusBarHidden()
        .task { viewModel.handle(.start) }
        .onDisappear { viewModel.handle(.stop) }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .showingResult, let result = viewModel.lastResult {
                if result.outcome.isGranted {
                    Haptics.success()
                } else {
                    Haptics.error()
                }
            }
        }
        .sheet(isPresented: showingResultBinding) {
            if let result = viewModel.lastResult {
                ResultSheetView(
                    result: result,
                    confirm: viewModel.confirm,
                    onConfirm: { viewModel.handle(.confirmAttendance) },
                    onClose: { viewModel.handle(.dismissResult) }
                )
                .presentationDetents([.fraction(0.6)])
                .presentationCornerRadius(38)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.6)))
                .interactiveDismissDisabled(true)
            }
        }
        .onChange(of: viewModel.confirm) { _, newValue in
            if case .done(let result) = newValue {
                switch result {
                case .registered:                 Haptics.success()
                case .alreadyScanned, .failure:   Haptics.warning()
                }
            }
        }
    }

    @ViewBuilder
    private func glassContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 26.0, *), LiquidGlassConfig.enabled {
            GlassEffectContainer { content() }
        } else {
            content()
        }
    }

    private var scannerStack: some View {
        ZStack {
            CameraPreviewView(session: viewModel.captureSession, scanFraction: 0.82)
                .ignoresSafeArea()

            QRTargetFrameView(isAnimating: viewModel.phase == .scanning)
                .allowsHitTesting(false)

            VStack {
                ScannerHeaderView(
                    onBack: { dismiss() }
                )
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 24) {
                    Text("Coloca el QR dentro del área")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)

                    torchButton
                }
                .padding(.bottom, 32)
            }

            if viewModel.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
                    .padding(28)
                    .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var showingResultBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isShowingResult },
            set: { newValue in
                if !newValue { viewModel.handle(.dismissResult) }
            }
        )
    }

    private var torchButton: some View {
        Button {
            Haptics.light()
            viewModel.handle(.toggleTorch)
        } label: {
            Image(systemName: viewModel.torchOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(viewModel.torchOn ? Color.egxBlue : .white)
                .frame(width: 68, height: 68)
                .contentShape(Circle())
                .clearGlassInteractive(in: Circle())
        }
        .buttonStyle(.plain)
    }
}
