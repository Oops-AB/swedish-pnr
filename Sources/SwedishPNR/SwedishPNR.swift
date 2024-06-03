import Foundation

public struct SwedishPNR {
    public let input: String
    public let normalized: String
    public let birthDateComponents: DateComponents
    public let birthDate: Date

    public func age(at reference: Date = Date()) -> Int {
        return calculateAge(for: birthDate, at: reference, in: makeSwedishCalendar())
    }
}


public struct Parser {
    enum ParseError: Error {
        case length(Int)
        case checksum(Int, Int)
        case format
        case date
        case referenceDate
    }

    var swedishCalendar: Calendar {
        return makeSwedishCalendar()
    }

    var earliestPossibleReferenceDate: Date {
        let components = DateComponents(year: 1947, month: 1, day: 1)
        return swedishCalendar.date(from: components)!
    }

    public func parse(input: any StringProtocol, relative reference: Date = Date()) throws -> SwedishPNR {
        guard reference >= earliestPossibleReferenceDate else {
            throw ParseError.referenceDate
        }

        let trimmed = input.trimmingCharacters(in: CharacterSet.whitespaces)

        guard trimmed.count >= 10 && trimmed.count <= 13 else {
            throw ParseError.length(trimmed.count)
        }

        var (birthDateComponents, birthNumber) = try extractBirthDateAndNumber(from: trimmed)
        try validateChecksum(trimmed)

        if (trimmed.count > 11) {
            birthDateComponents = try validDateFromFullBirthDate(birthDateComponents)
        } else {
            let isCentennial = trimmed.count == 11 && trimmed[trimmed.index(trimmed.startIndex, offsetBy: 6)] == "+"
            birthDateComponents = try deduceCenturyFromBirthDate(birthDateComponents, reference, isCentennial)
        }

        let normalized: String

        switch trimmed.count {
        case 10: fallthrough
        case 11: fallthrough
        case 12:
            normalized = String(format: "%04d%02d%02d-%04d", birthDateComponents.year!, birthDateComponents.month!, birthDateComponents.day!, birthNumber)
        default:
            normalized = trimmed
        }

        let bday = swedishCalendar.date(from: birthDateComponents)!

        return SwedishPNR(
            input: String(input),
            normalized: normalized,
            birthDateComponents: birthDateComponents,
            birthDate: bday)
    }

    private func deduceCenturyFromBirthDate(_ birthDate: DateComponents, _ reference: Date, _ isCentennial: Bool) throws -> DateComponents {
        var presentTime = reference
        var century = swedishCalendar.component(.year, from: presentTime) / 100

        if isCentennial {
            century -= 1
            presentTime = swedishCalendar.date(byAdding: .year, value: -100, to: presentTime)!
        }

        var candidate = DateComponents(
            year: 100*century + birthDate.year!,
            month: birthDate.month,
            day: birthDate.day! > 60 ? birthDate.day! - 60 : birthDate.day
        )

        if (!candidate.isValidDate(in: swedishCalendar) || swedishCalendar.compare(swedishCalendar.date(from: candidate)!, to: presentTime, toGranularity: isCentennial ? .year : .day) == .orderedDescending) {
            century -= 1
            candidate.year = 100*century + birthDate.year!
            
            if !candidate.isValidDate(in: swedishCalendar) {
                throw ParseError.date
            }
        }

        return candidate
    }

    private func validDateFromFullBirthDate(_ birthDate: DateComponents) throws -> DateComponents {
        var candidate = birthDate

        if let d = candidate.day, d > 60 {
            candidate.day = d - 60
        }

        if !candidate.isValidDate(in: swedishCalendar) {
            throw ParseError.date
        }

        return candidate
    }

    private func extractBirthDateAndNumber(from string: String) throws -> (DateComponents, Int) {
        /// yymmddnnnn
        /// yymmdd-nnnn
        /// yyyymmddnnnn
        /// yyyymmdd-nnnn

        let year,month,day,number : Int

        var cursor = string.startIndex

        if string.count == 10 || string.count == 11 {
            year = try scanNonNegativeInt(s: string[cursor..<string.endIndex], exactelyNumDigits: 2)
            cursor = string.index(cursor, offsetBy: 2)

        } else if string.count == 12 || string.count == 13 { 
            year = try scanNonNegativeInt(s: string[cursor..<string.endIndex], exactelyNumDigits: 4)
            cursor = string.index(cursor, offsetBy: 4)

        } else {
            throw ParseError.format
        }

        do {
            month = try scanNonNegativeInt(s: string[cursor..<string.endIndex], exactelyNumDigits: 2)
            cursor = string.index(cursor, offsetBy: 2)
        }
        do {
            day = try scanNonNegativeInt(s: string[cursor..<string.endIndex], exactelyNumDigits: 2)
            cursor = string.index(cursor, offsetBy: 2)
        }

        if string.count == 11 {
            let c = string[cursor]
            guard c == Character("-") || c == Character("+") else { throw ParseError.format }
            cursor = string.index(cursor, offsetBy: 1)
        } else if string.count == 13 {
            let c = string[cursor]
            guard c == Character("-") else { throw ParseError.format }
            cursor = string.index(cursor, offsetBy: 1)
        }

        do {
            number = try scanNonNegativeInt(s: string[cursor..<string.endIndex], exactelyNumDigits: 4)
            cursor = string.index(cursor, offsetBy: 4)
        }

        return (DateComponents(year: year, month: month, day: day), number)
    }

    /// This method assumes `pnr` is 10 to 13 digits long, including a possible (single!) separator.
    fileprivate func validateChecksum<S: StringProtocol>(_ pnr: S) throws {
        var cursor = pnr.startIndex

        if pnr.count > 11 {
            cursor = pnr.index(cursor, offsetBy: 2)
        }

        var sum: UInt8 = 0
        var r: UInt8 = 0

        r = 2 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 1 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 2 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 1 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 2 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 1 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)

        if pnr.count == 11 || pnr.count == 13 {
            cursor = pnr.index(after: cursor)
        }

        r = 2 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 1 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)
        r = 2 * (pnr[cursor].asciiValue! - 48); sum += r>9 ? 1+r-10 : r; cursor = pnr.index(after: cursor)

        var expectedChecksum = 10 - (sum % 10)
        if expectedChecksum == 10 { expectedChecksum = 0 }

        let actualChecksum = pnr.last!.asciiValue! - 48

        if expectedChecksum != actualChecksum {
            throw ParseError.checksum(Int(expectedChecksum), Int(actualChecksum))
        }
    }
}


fileprivate func scanNonNegativeInt<S: StringProtocol>(s: S, exactelyNumDigits: Int) throws -> Int {
    let (count, res) = scanUInt(s: s, maxdigits: exactelyNumDigits)

    guard count == exactelyNumDigits, let res = res else {
        throw Parser.ParseError.format
    }

    return Int(res)
}

fileprivate func scanUInt<S: StringProtocol>(s: S, maxdigits: Int) -> (count: Int, result: UInt?) {
    var result: UInt = 0
    var ndigits: Int = 0
    var i = s.startIndex

    while ndigits < maxdigits && i < s.endIndex {
        guard let c = s[i].asciiValue else { break }
        if (c < 48 || c > 57) { break }

        result *= 10
        result += UInt(c) - 48

        ndigits += 1
        i = s.index(after: i)
    }

    return (count: ndigits, result: result)
}


extension SwedishPNR {
    static public func parse(input: any StringProtocol, relative reference: Date = Date()) throws -> SwedishPNR {
        return try Parser().parse(input: input, relative: reference)
    }
}


fileprivate func calculateAge(for birthDate: Date, at reference: Date = Date(), in calendar: Calendar) -> Int {
    if reference.compare(birthDate) == .orderedAscending {
        return 0
    }

    return calendar.dateComponents([.year], from: birthDate, to: reference).year!
}


fileprivate func makeSwedishCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "sv_SE")
    cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return cal
}
