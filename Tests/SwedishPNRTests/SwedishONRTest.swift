import XCTest
@testable import SwedishPNR

final class SwedishONRTest: XCTestCase {

    func testInitiallyTrimmed() throws {
        do {
            _ = try SwedishONR.parse(input: "  123456789 ")
            XCTFail("unexpected success")
        } catch Parser.ParseError.length(let was) {
            XCTAssertEqual(was, 9)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testWrongLength() throws {
        do {
            _ = try SwedishONR.parse(input: "123456789")
            XCTFail("unexpected success")
        } catch Parser.ParseError.length(let was) {
            XCTAssertEqual(was, 9)
        } catch {
            XCTFail("unexpected error \(error)")
        }

        do {
            _ = try SwedishONR.parse(input: "123456789abcde")
            XCTFail("unexpected success")
        } catch Parser.ParseError.length(let was) {
            XCTAssertEqual(was, 14)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testBadChecksum() throws {
        do {
            _ = try SwedishONR.parse(input: "202100-5442")
            XCTFail("unexpected success")
        } catch Parser.ParseError.checksum(let expected, let was) {
            XCTAssertEqual(was, 2)
            XCTAssertEqual(expected, 8)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

}
