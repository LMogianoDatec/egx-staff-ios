import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var scanFraction: CGFloat = 1.0

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.scanFraction = scanFraction
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.scanFraction = scanFraction
        uiView.setNeedsLayout()
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var scanFraction: CGFloat = 1.0

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard scanFraction < 1.0,
              let session = videoPreviewLayer.session,
              let output = session.outputs.compactMap({ $0 as? AVCaptureMetadataOutput }).first
        else { return }

        let side = min(bounds.width, bounds.height) * scanFraction
        let layerRect = CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        )
        output.rectOfInterest = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: layerRect)
    }
}
