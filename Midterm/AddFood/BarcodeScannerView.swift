// ------------------------------------------------------------
// Written by Gladys Yu
// Camera scanner for barcodes and produce sticker (PLU) numbers
// ------------------------------------------------------------

import SwiftUI
import Vision
import VisionKit

enum ScanResult {
    case barcode(String)
    case plu(String)
}

struct ScannerScreen: View {
    var onScan: (ScanResult) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            BarcodeScannerView { result in
                onScan(result)
                dismiss()
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Point at a barcode, or the number sticker on fruit and vegetables")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                Button("Cancel") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (ScanResult) -> Void

    static var isSupported: Bool { DataScannerViewController.isSupported }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce, .code128]),
                .text()
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (ScanResult) -> Void
        private var done = false

        init(onScan: @escaping (ScanResult) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !done else { return }

            for item in allItems {
                if case .barcode(let barcode) = item,
                   let code = barcode.payloadStringValue, !code.isEmpty {
                    finish(.barcode(code), scanner: dataScanner)
                    return
                }
            }

            for item in allItems {
                if case .text(let text) = item,
                   let plu = ProductLookup.pluCode(in: text.transcript) {
                    finish(.plu(plu), scanner: dataScanner)
                    return
                }
            }
        }

        private func finish(_ result: ScanResult, scanner: DataScannerViewController) {
            done = true
            scanner.stopScanning()
            onScan(result)
        }
    }
}
