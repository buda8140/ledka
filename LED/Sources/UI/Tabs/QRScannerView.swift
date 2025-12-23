import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    var onScan: ((String) -> Void)?
    
    @State private var isCameraAuthorized = false
    @State private var scanAnim = false
    
    var body: some View {
        ZStack {
            if isCameraAuthorized {
                QRScannerController(onScan: { code in
                    Haptics.notify(.success)
                    onScan?(code)
                    dismiss()
                })
                .ignoresSafeArea()
            } else {
                Theme.background()
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.primaryNeon)
                    Text("Camera Access Required")
                        .font(.title3.bold())
                    Text("We need camera access to scan the controller QR code.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryNeon)
                }
            }
            
            // Premium Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    Spacer()
                    Text("SCAN QR CODE")
                        .font(.caption.bold())
                        .tracking(2)
                }
                .padding(25)
                
                Spacer()
                
                // Scanner Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 280, height: 280)
                    
                    // Corner Accents
                    ScannerCorners()
                        .stroke(Theme.primaryNeon, lineWidth: 4)
                        .frame(width: 280, height: 280)
                        .neonGlow()
                    
                    // Scanning Line
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Theme.primaryNeon, .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 260, height: 2)
                        .offset(y: scanAnim ? 130 : -130)
                }
                
                Text("Align the QR code on your LED controller within the frame")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                    .padding(.horizontal, 60)
                
                Spacer()
            }
        }
        .foregroundColor(.white)
        .onAppear {
            checkCameraPermission()
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                scanAnim = true
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { isCameraAuthorized = granted }
            }
        default:
            isCameraAuthorized = false
        }
    }
}

struct ScannerCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let len: CGFloat = 40
        
        // Top Left
        path.move(to: CGPoint(x: 0, y: len))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: len, y: 0))
        
        // Top Right
        path.move(to: CGPoint(x: rect.width - len, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: len))
        
        // Bottom Right
        path.move(to: CGPoint(x: rect.width, y: rect.height - len))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width - len, y: rect.height))
        
        // Bottom Left
        path.move(to: CGPoint(x: len, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - len))
        
        return path
    }
}

struct QRScannerController: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video) else { return viewController }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) { captureSession.addInput(input) }
            
            let output = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
                output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
                output.metadataObjectTypes = [.qr]
            }
            
            let preview = AVCaptureVideoPreviewLayer(session: captureSession)
            preview.frame = viewController.view.layer.bounds
            preview.videoGravity = .resizeAspectFill
            viewController.view.layer.addSublayer(preview)
            
            DispatchQueue.global(qos: .userInitiated).async { captureSession.startRunning() }
        } catch { }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerController
        init(_ parent: QRScannerController) { self.parent = parent }
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let stringValue = metadataObject.stringValue {
                parent.onScan(stringValue)
            }
        }
    }
}

