import SwiftUI
import VisionKit

struct CameraScannerView: UIViewControllerRepresentable {
    let isScanning: Bool
    let onRecognizedCode: (String) -> Void
    let onFailure: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce, .code128, .code39, .codabar, .itf14])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.parent = self

        if isScanning {
            guard !context.coordinator.isRunning else { return }
            do {
                try uiViewController.startScanning()
                context.coordinator.isRunning = true
            } catch {
                context.coordinator.isRunning = false
                onFailure("Failed to start camera scanning: \(error.localizedDescription)")
            }
        } else if context.coordinator.isRunning {
            uiViewController.stopScanning()
            context.coordinator.isRunning = false
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        if coordinator.isRunning {
            uiViewController.stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: CameraScannerView
        var isRunning = false

        private var lastCode = ""
        private var lastRecognizedAt = Date.distantPast

        init(parent: CameraScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(items: addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(items: updatedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            isRunning = false
            parent.onFailure("Camera scanning became unavailable: \(String(describing: error))")
        }

        private func handle(items: [RecognizedItem]) {
            for item in items {
                guard case .barcode(let barcode) = item,
                      let payload = barcode.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !payload.isEmpty else {
                    continue
                }

                let now = Date()
                if payload == lastCode && now.timeIntervalSince(lastRecognizedAt) < 1.2 {
                    continue
                }

                lastCode = payload
                lastRecognizedAt = now
                parent.onRecognizedCode(payload)
                break
            }
        }
    }
}
