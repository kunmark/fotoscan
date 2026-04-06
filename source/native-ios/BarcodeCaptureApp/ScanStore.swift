import Foundation
import SwiftUI

struct ScanRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let barcode: String
    let type: BarcodeType
    let scannedAt: Date

    var scanDateText: String {
        Formatters.date.string(from: scannedAt)
    }

    var scannedAtText: String {
        Formatters.dateTime.string(from: scannedAt)
    }
}

enum BarcodeType: String, Codable, Hashable {
    case isbn13 = "ISBN-13"
    case isbn10 = "ISBN-10"
    case ean8 = "EAN-8"
    case ean13 = "EAN-13"
    case upca = "UPC-A"
    case itf14 = "ITF-14"
    case retail = "Retail"
    case other = "Other"

    static func detect(from barcode: String) -> BarcodeType {
        if barcode.range(of: "^(978|979)\\d{10}$", options: .regularExpression) != nil {
            return .isbn13
        }

        if barcode.range(of: "^\\d{9}[\\dX]$", options: .regularExpression) != nil {
            return .isbn10
        }

        if barcode.range(of: "^\\d{8}$", options: .regularExpression) != nil {
            return .ean8
        }

        if barcode.range(of: "^\\d{12}$", options: .regularExpression) != nil {
            return .upca
        }

        if barcode.range(of: "^\\d{13}$", options: .regularExpression) != nil {
            return .ean13
        }

        if barcode.range(of: "^\\d{14}$", options: .regularExpression) != nil {
            return .itf14
        }

        if barcode.range(of: "^\\d{6,18}$", options: .regularExpression) != nil {
            return .retail
        }

        return .other
    }
}

func normalizeBarcodeValue(_ rawValue: String) -> String {
    rawValue
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: " ", with: "")
        .uppercased()
}

struct BarcodeSummary: Identifiable, Hashable {
    let barcode: String
    let type: BarcodeType
    let quantity: Int
    let firstScannedAt: Date
    let lastScannedAt: Date
    let scanDates: [String]

    var id: String { barcode }
    var firstScannedAtText: String { Formatters.dateTime.string(from: firstScannedAt) }
    var lastScannedAtText: String { Formatters.dateTime.string(from: lastScannedAt) }
}

struct StatusBanner: Equatable {
    enum Tone {
        case neutral
        case success
        case error
    }

    let message: String
    let tone: Tone

    var backgroundColor: Color {
        switch tone {
        case .neutral:
            return Color(uiColor: .secondarySystemBackground)
        case .success:
            return Color.green.opacity(0.16)
        case .error:
            return Color.red.opacity(0.16)
        }
    }

    var foregroundColor: Color {
        switch tone {
        case .neutral:
            return .secondary
        case .success:
            return Color.green.opacity(0.92)
        case .error:
            return Color.red.opacity(0.92)
        }
    }

    static func neutral(_ message: String) -> StatusBanner {
        StatusBanner(message: message, tone: .neutral)
    }

    static func success(_ message: String) -> StatusBanner {
        StatusBanner(message: message, tone: .success)
    }

    static func error(_ message: String) -> StatusBanner {
        StatusBanner(message: message, tone: .error)
    }
}

@MainActor
final class ScanStore: ObservableObject {
    @Published private(set) var scans: [ScanRecord] = []
    @Published private(set) var status = StatusBanner.neutral("Ready to scan. Supports Bluetooth scanner, manual entry, and camera scan.")

    private let saveURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        saveURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("barcode-scans.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    var totalScans: Int {
        scans.count
    }

    var uniqueCodes: Int {
        Set(scans.map(\.barcode)).count
    }

    var todayScans: Int {
        scans.filter { Calendar.current.isDateInToday($0.scannedAt) }.count
    }

    var summaries: [BarcodeSummary] {
        let grouped = Dictionary(grouping: scans, by: \.barcode)

        return grouped.values
            .compactMap { items in
                guard let firstItem = items.first else { return nil }
                let ordered = items.sorted { $0.scannedAt < $1.scannedAt }

                return BarcodeSummary(
                    barcode: firstItem.barcode,
                    type: firstItem.type,
                    quantity: items.count,
                    firstScannedAt: ordered.first?.scannedAt ?? firstItem.scannedAt,
                    lastScannedAt: ordered.last?.scannedAt ?? firstItem.scannedAt,
                    scanDates: Array(Set(items.map(\.scanDateText))).sorted()
                )
            }
            .sorted {
                if $0.quantity != $1.quantity {
                    return $0.quantity > $1.quantity
                }
                return $0.barcode < $1.barcode
            }
    }

    var recentScans: [ScanRecord] {
        Array(scans.prefix(200))
    }

    func addScan(rawValue: String) {
        let barcode = normalizeBarcodeValue(rawValue)

        guard !barcode.isEmpty else {
            status = .error("Enter or scan a valid barcode.")
            return
        }

        let record = ScanRecord(
            id: UUID(),
            barcode: barcode,
            type: BarcodeType.detect(from: barcode),
            scannedAt: Date()
        )

        scans.insert(record, at: 0)
        persist()

        let duplicateCount = scans.filter { $0.barcode == barcode }.count
        let suffix = duplicateCount > 1 ? ", total \(duplicateCount) items" : ""
        status = .success("Saved \(barcode) (\(record.type.rawValue))\(suffix)")
    }

    func clearAll() {
        scans.removeAll()
        persist()
        status = .success("All scan records were cleared.")
    }

    func seedDemoData() {
        [
            "9787111128069",
            "9787111128069",
            "6901028075885",
            "9787302511850",
            "4901777302159"
        ].forEach(addScan(rawValue:))
    }

    func makeRawExportURL() -> URL? {
        guard !scans.isEmpty else {
            status = .error("No raw scan data to export.")
            return nil
        }

        let header = ["barcode", "type", "scan_date", "scanned_at_local"]
        let rows = scans.reversed().map { scan in
            [
                scan.barcode,
                scan.type.rawValue,
                scan.scanDateText,
                scan.scannedAtText
            ]
        }

        return writeCSV(header: header, rows: rows, prefix: "barcode-raw")
    }

    func makeSummaryExportURL() -> URL? {
        let currentSummaries = summaries
        guard !currentSummaries.isEmpty else {
            status = .error("No summary data to export.")
            return nil
        }

        let header = ["barcode", "type", "quantity", "first_scanned_at_local", "last_scanned_at_local", "scan_dates"]
        let rows = currentSummaries.map { summary in
            [
                summary.barcode,
                summary.type.rawValue,
                String(summary.quantity),
                summary.firstScannedAtText,
                summary.lastScannedAtText,
                summary.scanDates.joined(separator: " | ")
            ]
        }

        return writeCSV(header: header, rows: rows, prefix: "barcode-summary")
    }

    private func writeCSV(header: [String], rows: [[String]], prefix: String) -> URL? {
        let csv = ([header] + rows)
            .map { row in row.map(csvEscape).joined(separator: ",") }
            .joined(separator: "\r\n")

        let fileName = "\(prefix)-\(Formatters.date.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try Data(("\u{FEFF}" + csv).utf8).write(to: url, options: .atomic)
            status = .success("CSV generated successfully. You can share it to Files or Mail.")
            return url
        } catch {
            status = .error("Failed to export CSV: \(error.localizedDescription)")
            return nil
        }
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\r") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: saveURL)
            scans = try decoder.decode([ScanRecord].self, from: data)
                .sorted { $0.scannedAt > $1.scannedAt }
        } catch {
            status = .error("Failed to read local data: \(error.localizedDescription)")
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(scans)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            status = .error("Failed to save local data: \(error.localizedDescription)")
        }
    }
}

private enum Formatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
