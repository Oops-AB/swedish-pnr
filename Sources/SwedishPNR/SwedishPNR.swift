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

extension SwedishPNR {
    enum ParseError: Error {
        case length(Int)
        case checksum(Int, Int)
        case format
        case date
        case referenceDate
    }

    public struct Parser {
        var swedishCalendar: Calendar {
            return makeSwedishCalendar()
        }

        public func parse(input: any StringProtocol, relative reference: Date = Date()) throws -> SwedishPNR {
            guard reference >= SwedishPNR.earliestPossibleReferenceDate else {
                throw ParseError.referenceDate
            }
            
            return SwedishPNR(input: String(input), normalized: String(input), birthDateComponents: DateComponents(), birthDate: Date(), age: 0)
        }
    }

    static public func parse(input: any StringProtocol, relative reference: Date = Date()) throws -> SwedishPNR {
        return try Parser().parse(input: input, relative: reference)
    }

    static var earliestPossibleReferenceDate: Date {
        let cal = makeSwedishCalendar()
        let components = DateComponents(year: 1947, month: 1, day: 1)
        return cal.date(from: components)!
    }
}

fileprivate func makeSwedishCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "sv_SE")
    cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return cal
}
