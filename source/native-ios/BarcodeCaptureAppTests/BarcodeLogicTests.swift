import XCTest
@testable import BarcodeCaptureApp

@MainActor
final class BarcodeLogicTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearPersistedScanData()
    }

    override func tearDown() {
        clearPersistedScanData()
        super.tearDown()
    }

    func testNormalizeBarcodeValueRemovesWhitespaceHyphensAndUppercases() {
        let result = normalizeBarcodeValue(" 978-7 1111-28069 \n")
        XCTAssertEqual(result, "9787111128069")
    }

    func testBarcodeTypeDetectRecognizesISBN13() {
        XCTAssertEqual(BarcodeType.detect(from: "9787111128069"), .isbn13)
    }

    func testBarcodeTypeDetectRecognizesRetailFallback() {
        XCTAssertEqual(BarcodeType.detect(from: "6901028075886"), .ean13)
        XCTAssertEqual(BarcodeType.detect(from: "1234567"), .retail)
    }

    func testBarcodeTypeDetectRejectsInvalidStructuredBarcodeChecksums() {
        XCTAssertEqual(BarcodeType.detect(from: "9787111128060"), .other)
        XCTAssertEqual(BarcodeType.detect(from: "12345670"), .other)
        XCTAssertEqual(BarcodeType.detect(from: "036000291453"), .other)
    }

    func testScanStoreAggregatesDuplicateScansIntoSummary() {
        let store = ScanStore()

        store.addScan(rawValue: "9787111128069")
        store.addScan(rawValue: "9787111128069")
        store.addScan(rawValue: "4901777302150")

        XCTAssertEqual(store.totalScans, 3)
        XCTAssertEqual(store.uniqueCodes, 2)
        XCTAssertEqual(store.summaries.first?.barcode, "9787111128069")
        XCTAssertEqual(store.summaries.first?.quantity, 2)
    }

    func testRawExportRequiresData() {
        let store = ScanStore()
        XCTAssertNil(store.makeRawExportURL())
    }

    func testScanStoreRejectsInvalidStructuredBarcode() {
        let store = ScanStore()

        store.addScan(rawValue: "9787111128060")

        XCTAssertEqual(store.totalScans, 0)
        XCTAssertEqual(store.uniqueCodes, 0)
        XCTAssertEqual(store.status.tone, .error)
    }

    private func clearPersistedScanData() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let saveURL = documents.appendingPathComponent("barcode-scans.json")
        try? FileManager.default.removeItem(at: saveURL)
    }
}
