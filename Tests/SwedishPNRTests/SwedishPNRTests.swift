import XCTest
@testable import SwedishPNR

enum TestError: Error {
    case date
}

final class SwedishPNRTests: XCTestCase {

    var formatterForSweden: DateFormatter?
    var now: Date?

    override func setUp() async throws {
        formatterForSweden = makeFormatterForSwedishDatesWithFormat(format: "yyyy-MM-dd")
        now = formatterForSweden!.date(from: "2017-12-12")!
    }

    override func tearDown() async throws {
        formatterForSweden = nil
    }

    func components(_ year: Int, _ month: Int, _ day: Int) -> DateComponents {
        return DateComponents(year: year, month: month, day: day)
    }

    func testValidIdentificationNumbers() throws {
        struct test {
            let name: String
            let input: String
            let normalized: String
            let birthDateComponents: DateComponents
        }

        let fixture: [test] = [
            test(name: "13 dgt",             input: "20171210-0005", normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "12 dgt",             input: "201712100005",  normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "11 dgt",             input:   "171210-0005", normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "10 dgt",             input:   "1712100005",  normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),

            test(name: "trimmed",            input:  " 171210-0005 ",normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),

            test(name: "100+",               input:   "171210+0005", normalized: "19171210-0005", birthDateComponents: self.components(1917, 12, 10)),

            test(name: "sam.13",             input: "20171270-0002", normalized: "20171270-0002", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "sam.11",             input:   "171270-0002", normalized: "20171210-0002", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "sam.11 100+",        input:   "171270+0002", normalized: "19171210-0002", birthDateComponents: self.components(1917, 12, 10)),

            test(name: "deduce this cent 1", input:   "171210-0005", normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "deduce this cent 2", input:   "1712100005",  normalized: "20171210-0005", birthDateComponents: self.components(2017, 12, 10)),
            test(name: "deduce this cent 3", input:   "160601-0005", normalized: "20160601-0005", birthDateComponents: self.components(2016,  6,  1)),
            test(name: "deduce this cent 4", input:   "1606010005",  normalized: "20160601-0005", birthDateComponents: self.components(2016,  6,  1)),

            test(name: "deduce last cent",   input:   "171218-0007", normalized: "19171218-0007", birthDateComponents: self.components(1917, 12, 18)),
            test(name: "deduce last cent",   input:   "1712180007",  normalized: "19171218-0007", birthDateComponents: self.components(1917, 12, 18)),
            test(name: "deduce last cent",   input:   "180601-0003", normalized: "19180601-0003", birthDateComponents: self.components(1918,  6,  1)),
            test(name: "deduce last cent",   input:   "1806010003",  normalized: "19180601-0003", birthDateComponents: self.components(1918,  6,  1)),

            test(name: "deduce cent 100+",   input:   "171210+0005", normalized: "19171210-0005", birthDateComponents: self.components(1917, 12, 10)),
            test(name: "deduce cent 100+",   input:   "160601+0005", normalized: "19160601-0005", birthDateComponents: self.components(1916,  6,  1)),
            test(name: "deduce cent 100+",   input:   "171218+0007", normalized: "19171218-0007", birthDateComponents: self.components(1917, 12, 18)),
            test(name: "deduce cent 100+",   input:   "180601+0003", normalized: "18180601-0003", birthDateComponents: self.components(1818,  6,  1)),
        ]
        
        for t in fixture {
            do {
                let pnr = try SwedishPNR.parse(input: t.input, relative: self.now!)
                XCTAssertEqual(pnr.input, t.input, "\(t.name) input")
                XCTAssertEqual(pnr.normalized, t.normalized, "\(t.name) normalized")
                XCTAssertEqual(pnr.birthDateComponents, t.birthDateComponents, "\(t.name) bday comps")
            } catch {
                XCTFail("\(t.name) unexpected error: \(error)")
                continue
            }
        }
    }

    func testInitiallyTrimmed() throws {
        do {
            _ = try SwedishPNR.parse(input: "  123456789 ", relative: self.now!)
            XCTFail("unexpected success")
        } catch Parser.ParseError.length(let was) {
            XCTAssertEqual(was, 9)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testWrongLength() throws {
        do {
            _ = try SwedishPNR.parse(input: "123456789", relative: self.now!)
            XCTFail("unexpected success")
        } catch Parser.ParseError.length(let was) {
            XCTAssertEqual(was, 9)
        } catch {
            XCTFail("unexpected error \(error)")
        }

        do {
            _ = try SwedishPNR.parse(input: "123456789abcde", relative: self.now!)
            XCTFail("unexpected success")
        } catch Parser.ParseError.length(let was) {
            XCTAssertEqual(was, 14)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testBadChecksum() throws {
        do {
            _ = try SwedishPNR.parse(input: "20171210-0003", relative: self.now!)
            XCTFail("unexpected success")
        } catch Parser.ParseError.checksum(let expected, let was) {
            XCTAssertEqual(was, 3)
            XCTAssertEqual(expected, 5)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testIllegalFormat() throws {
        let illegals = [
            // 10-digit
            "x712149876",
            "1x12149876",
            "17x2149876",
            "171x149876",
            "1712x49876",
            "17121x9876",
            "171214x876",
            "1712149x76",
            "17121498x6",
            "171214987x",
 
            // 11-digit
            "x71214-9876",
            "1x1214-9876",
            "17x214-9876",
            "171x14-9876",
            "1712x4-9876",
            "17121x-9876",
            "171214-x876",
            "171214-9x76",
            "171214-98x6",
            "171214-987x",

            // 12-digit
            "x01712149876",
            "2x1712149876",
            "20x712149876",
            "201x12149876",
            "2017x2149876",
            "20171x149876",
            "201712x49876",
            "2017121x9876",
            "20171214x876",
            "201712149x76",
            "2017121498x6",
            "20171214987x",

            // 13-digit
            "x0171214-9876",
            "2x171214-9876",
            "20x71214-9876",
            "201x1214-9876",
            "2017x214-9876",
            "20171x14-9876",
            "201712x4-9876",
            "2017121x-9876",
            "20171214-x876",
            "20171214-9x76",
            "20171214-98x6",
            "20171214-987x",

            // 11-digit separator
            "171214/9876",

            // 13-digit separator
            "20171214/9876",
            "20171214+9876",
        ]

        for illegal in illegals {
            do {
                _ = try SwedishPNR.parse(input: illegal, relative: self.now!)
                XCTFail("\(illegal) expected format error, had success")
            } catch Parser.ParseError.format {
            } catch {
                XCTFail("\(illegal) expected format error, got \(error)")
            }
        }
    }

    func testIllegalDate() throws {
        let illegals = [
            "20170229-1236",

            // samordningsnummer
            "20170260-1236",
            "20170293-1237",
            "20170289-1233",
        ]

        for illegal in illegals {
            do {
                _ = try SwedishPNR.parse(input: illegal, relative: self.now!)
                XCTFail("\(illegal) expected date error, had success")
            } catch Parser.ParseError.date {
            } catch {
                XCTFail("\(illegal) expected date error, got \(error)")
            }
        }
    }

    func testThrowsWhenDeducedDateInThisCenturyDoesNotExit() throws {
        let ref = formatterForSweden!.date(from: "2017-12-08")!

        do {
            _ = try SwedishPNR.parse(input: "130229-0000", relative: ref)
            XCTFail("unexpected success")
        } catch Parser.ParseError.date {
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testThrowsWhenDeducedDateInLastCenturyDoesNotExit() throws {
        // 2000-02-29 does exist while 1900-02-29 does not.
        // So, if it's 2000-02-01 and we want to deduce the birth year from "000229" our first candidate will be '20000229' which does exist, but because it's in the future we'll look in the past century instead. We form '1900-02-29' and conclude that the candidate date doesn't exist (because 1900 is not a leap year).
        let ref = formatterForSweden!.date(from: "2000-02-01")!

        do {
            _ = try SwedishPNR.parse(input: "000229-0005", relative: ref)
            XCTFail("unexpected success")
        } catch Parser.ParseError.date {
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testThrowsWhenDeducedDateDoesNotExistInThisOrLastCentury() throws {
        let ref = formatterForSweden!.date(from: "2001-02-01")!

        do {
            _ = try SwedishPNR.parse(input: "010229-0004", relative: ref)
            XCTFail("unexpected success")
        } catch Parser.ParseError.date {
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testThrowsWhenDeducedDateInThisCenturyDoesNotExist() throws {
        // 2400-02-29 does exist while 2500-02-29 does not.
        // If it's 2500-02-28 and we want to deduce '000229', then the candidate '2500-02-29' doesn't exist
        // (and if it would have existed it had been in the future),
        // so the next candidate '2400-02-29' is and it does exist, and it is less than 100 years in the past.
        let ref = formatterForSweden!.date(from: "2500-02-01")!

        let pnr = try SwedishPNR.parse(input: "000229-0005", relative: ref)
        XCTAssertEqual(pnr.input, "000229-0005")
        XCTAssertEqual(pnr.normalized, "24000229-0005")
        XCTAssertEqual(pnr.birthDateComponents, self.components(2400, 2, 29))
    }

    func testIncludeReferenceDayInSearch() throws {
        var referenceTime = formatterForSweden!.date(from: "2017-12-08")!

        var pnr = try SwedishPNR.parse(input: "171208-0009", relative: referenceTime)
        XCTAssertEqual(pnr.normalized, "20171208-0009")
        
        let formatterWithTime = makeFormatterForSwedishDatesWithFormat(format: "yyyy-MM-dd HH:mm")
        referenceTime = formatterWithTime.date(from: "2017-12-08 23:55")!
        pnr = try SwedishPNR.parse(input: "171208-0009", relative: referenceTime)
        XCTAssertEqual(pnr.normalized, "20171208-0009")

        // And just for reference: the day after we deduce the same century.
        referenceTime = formatterForSweden!.date(from: "2017-12-09")!
        pnr = try SwedishPNR.parse(input: "171208-0009", relative: referenceTime)
        XCTAssertEqual(pnr.normalized, "20171208-0009")

        // ...but the day before, we would've deduced the previous century
        referenceTime = formatterWithTime.date(from: "2017-12-07 23:59")!
        pnr = try SwedishPNR.parse(input: "171208-0009", relative: referenceTime)
        XCTAssertEqual(pnr.normalized, "19171208-0009")
    }

    func testCannotDeduceYearWithTooOldReferenceDate() throws {
        /* Personnummer were introduced in 1947, then with a three digit birth number. The checksum digit was added in 1967. We can reasonably assume that 1947-01-01 is a safe choice for the the earliest possible reference date. */
        var ref = formatterForSweden!.date(from: "1946-12-31")!

        do {
            _ = try SwedishPNR.parse(input: "171210-0005", relative: ref)
            XCTFail("unexpected success")
        } catch Parser.ParseError.referenceDate {
        } catch {
            XCTFail("unexpected error \(error)")
        }

        ref = formatterForSweden!.date(from: "1947-01-01")!
        let pnr = try SwedishPNR.parse(input: "171210-0005", relative: ref)
        XCTAssertEqual(pnr.normalized, "19171210-0005")
    }

    func testCenturyCalculatedInSwedishCalendar() throws {
        // Sweden is UTC+0100 in winter. First verify our 
        let formatterForUTC = makeFormatterForUTCDatesWithFormat(format: "yyyy-MM-dd HH:mm")
        let formatterForSWE = makeFormatterForSwedishDatesWithFormat(format: "yyyy-MM-dd HH:mm")

        let endOfLastMilleniumInUTC = formatterForUTC.date(from: "1999-12-31 23:55")!
        let endOfLastMilleniumInSWE = formatterForSWE.date(from: "1999-12-31 23:55")!

        XCTAssertEqual(formatterForSweden!.string(from: endOfLastMilleniumInUTC), "2000-01-01")
        XCTAssertEqual(formatterForSweden!.string(from: endOfLastMilleniumInSWE), "1999-12-31")

        var pnr = try SwedishPNR.parse(input: "000101-0008", relative: endOfLastMilleniumInUTC)
        XCTAssertEqual(pnr.normalized, "20000101-0008")

        pnr = try SwedishPNR.parse(input: "000101-0008", relative: endOfLastMilleniumInSWE)
        XCTAssertEqual(pnr.normalized, "19000101-0008")
    }

    func testAge() throws {
        var ref = formatterForSweden!.date(from: "2022-01-01")!
        XCTAssertEqual(try SwedishPNR.parse(input: "000101-0008", relative: ref).age, 22)

        ref = formatterForSweden!.date(from: "2022-06-12")!
        XCTAssertEqual(try SwedishPNR.parse(input: "20220611-0005", relative: ref).age, 0, "born yesterday")
        XCTAssertEqual(try SwedishPNR.parse(input: "20220612-0004", relative: ref).age, 0, "born today")
        XCTAssertEqual(try SwedishPNR.parse(input: "20720612-0003", relative: ref).age, 0, "born in the future")
    }

    func testAgeAt() throws {
        let fmt = makeFormatterForSwedishDatesWithFormat(format: "yyyy-MM-dd HH:mm:SS")
        let ref = fmt.date(from: "2022-01-01 00:00:00")!
        let pnr = try SwedishPNR.parse(input: "000101-0008", relative: ref)
        
        XCTAssertEqual(pnr.age(at: fmt.date(from: "2022-01-01 00:00:00")!), 22, "birthday, start")
        XCTAssertEqual(pnr.age(at: fmt.date(from: "2022-01-01 23:59:59")!), 22, "birthday, end")

        XCTAssertEqual(pnr.age(at: fmt.date(from: "2021-12-31 00:00:00")!), 21, "day before birthday")
        XCTAssertEqual(pnr.age(at: fmt.date(from: "2021-12-31 23:59:59")!), 21, "day before birthday")

        XCTAssertEqual(pnr.age(at: fmt.date(from: "2000-01-01 00:00:00")!), 0, "birth date, start")
        XCTAssertEqual(pnr.age(at: fmt.date(from: "2000-01-01 23:59:59")!), 0, "birth date, end")

        XCTAssertEqual(pnr.age(at: fmt.date(from: "1999-12-31 23:59:59")!), 0, "before birth date")
        XCTAssertEqual(pnr.age(at: fmt.date(from: "1999-01-01 00:00:00")!), 0, "before birth date")
        XCTAssertEqual(pnr.age(at: fmt.date(from: "1975-04-23 12:12:12")!), 0, "before birth date")
    }

    func testMenOfOldAndDwarvesAndElves() throws {
        var ref = formatterForSweden!.date(from: "2022-01-01")!

        XCTAssertEqual(try SwedishPNR.parse(input: "19000101-0008", relative: ref).age, 122)
        XCTAssertEqual(try SwedishPNR.parse(input: "18000101-0008", relative: ref).age, 222)
        XCTAssertEqual(try SwedishPNR.parse(input: "10660101-0009", relative: ref).age, 956)

        ref = formatterForSweden!.date(from: "2122-01-01")!
        XCTAssertEqual(try SwedishPNR.parse(input: "10000101-0008", relative: ref).age, 1122)
    }

    func testDefaultRefTime() throws {
        let pnr = try SwedishPNR.parse(input: "20000101-0008")
        
        let bday = formatterForSweden!.date(from: "2000-01-01")!
        let rightNow = Date()
        let diff = makeSwedishCalendar().dateComponents([.year], from: bday, to: rightNow).year!
        
        XCTAssert(pnr.age >= 22)
        XCTAssert(pnr.age >= diff)
        XCTAssert(pnr.age <= diff + 5)
    }

    func makeFormatterForSwedishDatesWithFormat(format: String) -> DateFormatter {
        let calendar = makeSwedishCalendar()
        return makeFormatter(calendar: calendar, format: format)
    }

    func makeFormatterForUTCDatesWithFormat(format: String) -> DateFormatter {
        let calendar = makeUTCCalendar()
        return makeFormatter(calendar: calendar, format: format)
    }

    func makeFormatter(calendar: Calendar, format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter
    }

    func makeSwedishCalendar() -> Calendar {
        var cal: Calendar = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "sv_SE")
        cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return cal
    }

    func makeUTCCalendar() -> Calendar {
        var cal: Calendar = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }
}
