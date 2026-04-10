import SwiftUI
import VisionKit

struct ContentView: View {
    @EnvironmentObject private var store: ScanStore

    @State private var inputText = ""
    @State private var focusToken = UUID()
    @State private var isShowingClearAlert = false
    @State private var sharePayload: SharePayload?
    @State private var captureMode: CaptureMode = .keyboard
    @State private var isCameraScanning = false
    @State private var cameraStatus = StatusBanner.neutral("Switch to camera mode to scan with the iPad rear camera.")

    private let statColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    private var supportsDataScanner: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsSection
                    captureSection
                    summarySection
                    logSection
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Barcode Capture")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Focus Input") {
                        refocusScanner()
                    }
                    .disabled(captureMode != .keyboard)

                    Button("Demo Data") {
                        store.seedDemoData()
                    }
                }
            }
            .sheet(item: $sharePayload) { payload in
                ShareSheet(activityItems: [payload.url])
            }
            .alert("Clear all records?", isPresented: $isShowingClearAlert) {
                Button("Cancel", role: .cancel) {
                }
                Button("Clear", role: .destructive) {
                    stopCameraIfNeeded()
                    store.clearAll()
                    refocusScanner()
                }
            } message: {
                Text("This deletes all locally saved scan data.")
            }
            .onAppear {
                refocusScanner()
            }
            .onChange(of: captureMode) { newMode in
                handleCaptureModeChange(newMode)
            }
        }
    }

    private var statsSection: some View {
        LazyVGrid(columns: statColumns, spacing: 12) {
            StatCard(title: "Total Scans", value: "\(store.totalScans)")
            StatCard(title: "Unique Codes", value: "\(store.uniqueCodes)")
            StatCard(title: "Today", value: "\(store.todayScans)")
        }
    }

    private var captureSection: some View {
        PanelCard(title: "Capture", subtitle: "Use a Bluetooth scanner in HID Keyboard mode, or switch to camera mode.") {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Capture Mode", selection: $captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if captureMode == .keyboard {
                    VStack(alignment: .leading, spacing: 14) {
                        ScannerInputField(
                            text: $inputText,
                            focusToken: focusToken,
                            placeholder: "Scan with Bluetooth scanner or type then press Return",
                            onSubmit: submitScan
                        )
                        .frame(height: 54)

                        HStack(spacing: 12) {
                            Button(action: submitScan) {
                                Label("Save Scan", systemImage: "barcode.viewfinder")
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Focus Input") {
                                refocusScanner()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    cameraSection
                }

                StatusBannerView(status: store.status)

                HStack(spacing: 12) {
                    Button("Export Raw CSV") {
                        if let url = store.makeRawExportURL() {
                            sharePayload = SharePayload(url: url)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Export Summary CSV") {
                        if let url = store.makeSummaryExportURL() {
                            sharePayload = SharePayload(url: url)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Clear All", role: .destructive) {
                        isShowingClearAlert = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder
    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if supportsDataScanner {
                CameraScannerView(
                    isScanning: isCameraScanning,
                    onRecognizedCode: handleRecognizedCode,
                    onFailure: handleCameraFailure
                )
                .frame(minHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )

                HStack(spacing: 12) {
                    Button(isCameraScanning ? "Scanning..." : "Start Camera") {
                        isCameraScanning = true
                        cameraStatus = .neutral("Camera is ready. Place the barcode inside the highlighted area.")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCameraScanning)

                    Button("Stop Camera") {
                        stopCameraIfNeeded()
                        cameraStatus = .neutral("Camera stopped. You can start it again or switch back to keyboard mode.")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isCameraScanning)
                }
            } else {
                EmptyStateView(text: "This device does not support DataScannerViewController. Continue with Bluetooth scanner or manual entry.")
            }

            StatusBannerView(status: cameraStatus)
        }
    }

    private var summarySection: some View {
        PanelCard(title: "Summary", subtitle: "Duplicate scans are grouped and counted automatically.") {
            if store.summaries.isEmpty {
                EmptyStateView(text: "No summary data yet. Add a scan to get started.")
            } else {
                VStack(spacing: 0) {
                    ForEach(store.summaries) { summary in
                        SummaryRowView(summary: summary)
                        if summary.id != store.summaries.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var logSection: some View {
        PanelCard(title: "Recent Scans", subtitle: "Each scan stores both date and exact local time.") {
            if store.recentScans.isEmpty {
                EmptyStateView(text: "No scan log yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(store.recentScans) { scan in
                        ScanRowView(scan: scan)
                        if scan.id != store.recentScans.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func submitScan() {
        store.addScan(rawValue: inputText)
        inputText = ""
        refocusScanner()
    }

    private func handleCaptureModeChange(_ mode: CaptureMode) {
        if mode == .keyboard {
            stopCameraIfNeeded()
            cameraStatus = .neutral("Switch back to camera mode anytime.")
            refocusScanner()
        } else {
            inputText = ""
            cameraStatus = supportsDataScanner
                ? .neutral("Tap Start Camera, then place a barcode in the live preview.")
                : .error("Camera scanning is unavailable on this device.")
        }
    }

    private func handleRecognizedCode(_ rawValue: String) {
        store.addScan(rawValue: rawValue)
        cameraStatus = .success("Recognized and saved: \(rawValue)")
    }

    private func handleCameraFailure(_ message: String) {
        isCameraScanning = false
        cameraStatus = .error(message)
    }

    private func stopCameraIfNeeded() {
        isCameraScanning = false
    }

    private func refocusScanner() {
        guard captureMode == .keyboard else { return }
        focusToken = UUID()
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

private enum CaptureMode: String, CaseIterable, Identifiable {
    case keyboard
    case camera

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyboard:
            return "Keyboard"
        case .camera:
            return "Camera"
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PanelCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct StatusBannerView: View {
    let status: StatusBanner

    var body: some View {
        Text(status.message)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(status.backgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(status.foregroundColor)
    }
}

private struct SummaryRowView: View {
    let summary: BarcodeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(summary.barcode)
                    .font(.headline.monospaced())
                    .textSelection(.enabled)
                Spacer()
                Text("\(summary.quantity) pcs")
                    .font(.headline)
                    .foregroundStyle(.tint)
            }

            HStack(spacing: 12) {
                Label(summary.type.rawValue, systemImage: "tag")
                Label(summary.firstScannedAtText, systemImage: "clock")
                Label(summary.lastScannedAtText, systemImage: "arrow.clockwise")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("Scan dates: \(summary.scanDates.joined(separator: " | "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}

private struct ScanRowView: View {
    let scan: ScanRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(scan.barcode)
                    .font(.headline.monospaced())
                    .textSelection(.enabled)
                Spacer()
                Text(scan.type.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 12) {
                Label(scan.scannedAtText, systemImage: "clock")
                Label(scan.scanDateText, systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}

private struct EmptyStateView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
