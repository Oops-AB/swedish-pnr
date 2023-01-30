import Foundation

public struct SwedishPNR {
    public let input: String
    public let normalized: String
    public let birthDateComponents: DateComponents
    public let birthDate: Date
    public let age: UInt 

    public func age(at reference: Date) -> UInt {
        return 0
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

        return SwedishPNR(input: String(input), normalized: trimmed, birthDateComponents: DateComponents(), birthDate: Date(), age: 0)
    }
}


extension SwedishPNR {

    static public func parse(input: any StringProtocol, relative reference: Date = Date()) throws -> SwedishPNR {
        return try Parser().parse(input: input, relative: reference)
    }
}


fileprivate func makeSwedishCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "sv_SE")
    cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return cal
}
