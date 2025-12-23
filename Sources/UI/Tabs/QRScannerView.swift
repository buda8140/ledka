import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var btManager: BluetoothManager
    var onScan: ((String) -> Void)?
    
    @State private var isCameraAuthorized = false
    @State private var scanAnim = false
    
    var body: some View {
        ZStack {
            if isCameraAuthorized {
                QRScannerController(onScan: { code in
                    handleScannedCode(code)
                })
                .ignoresSafeArea()
            } else {
                // ... camera permission view ...
            }
            // ... premium overlay ...
        }
        // ... appearance logic ...
    }
    
    private func handleScannedCode(_ code: String) {
        Haptics.notify(.success)
        onScan?(code)
        
        // Parse MAC Address (e.g. AA:BB:CC:DD:EE:FF or hex AA-BB-CC...)
        let macPattern = "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})"
        if let range = code.range(of: macPattern, options: .regularExpression) {
            let mac = String(code[range]).replacingOccurrences(of: "-", with: ":").uppercased()
            print("Found MAC: \(mac)")
            
            // Attempt to connect if we already discovered it
            if let peripheral = btManager.discoveredDevices.first(where: { 
                $0.identifier.uuidString.contains(mac) || ($0.name?.contains(mac) ?? false) 
            }) {
                btManager.connect(to: peripheral)
                dismiss()
            } else {
                // Not found in scan yet, but we have the target
                // For a real implementation, we could store this as "target MAC" 
                // and BluetoothManager would auto-connect when seen.
                dismiss()
            }
        } else {
            // Just generic code
            dismiss()
        }
    }
    
    private func checkCameraPermission() {
        // ...
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

