import ArgumentParser
import Foundation
import SwedishPNR

@main
struct verifypnr: ParsableCommand {

    @Argument(help: "Identity numbers to verify")
    var identityNumbers: [String]

    @Option(name: .shortAndLong, help: "Reference date that date calculations are based on. Defaults to today.", transform: str2date)
    var referenceDate: Date = today()

    mutating func run() throws {
        print("Parse identity number relative \(DateFormatter.swedishDate.string(from: referenceDate))")

        for each in identityNumbers {
            do {
                let pnr = try SwedishPNR.parse(input: each, relative: referenceDate)

                print("\(each)")

                if pnr.normalized != each {
                    print("  \(pnr.normalized)")
                }
                print("  age \(pnr.age(at: referenceDate))")

            } catch let parseError as Parser.ParseError {
                switch parseError {

                case .checksum(let expected, let actual):
                    print("\(each): checksum mismatch, was \(actual) but expected \(expected)")

                case .date:
                    print("\(each): birth date doesn't exist")

                case .format:
                    print("\(each): invalid format")

                case .length(let length):
                    print("\(each): wrong length \(length)")

                case .referenceDate:
                    print("\(each): invalid reference date")
                }
            }
        }
    }

    static func today() -> Date {
        var cal: Calendar = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "sv_SE")
        cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return cal.startOfDay(for: Date())
    }

    static func str2date(_ s: String) throws -> Date {
        guard let date = DateFormatter.swedishDate.date(from: s) else {
            throw ValidationError("not a date")
        }
        
        return date
    }

}
