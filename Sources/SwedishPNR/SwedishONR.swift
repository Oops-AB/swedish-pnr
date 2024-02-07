import Foundation

public struct SwedishONR {
    public let input: String
    public let normalized: String

    static public func parse(input: any StringProtocol, relative reference: Date = Date()) throws -> SwedishONR {
        return try Parser().parseONR(input: input)
    }
}
