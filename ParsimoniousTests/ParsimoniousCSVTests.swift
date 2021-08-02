//
//  ParsimoniousCSVTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 5/9/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

enum CSValue {
    case string(String)
    case integer(Int)
    case decimal(Decimal)
}

func toDecimal(_ string: String) -> CSValue {
    return .decimal(Decimal(string: string)!)
}

func toInteger(_ string: String) -> CSValue {
    return .integer(Int(string)!)
}

func delimited<T>(_ parser: @escaping Parser<String, T>) -> Parser<String, T> {
    return surround(parser, with: ows) <* peek(char(sep) | eol | eofS)
}

func csvError(_ rest: Substring?) -> String {
    guard let rest = rest else {
        return "Expected to match a CSV value but got EOF."
    }
    return "Expected to match a CSV value but got garbage starting with \(rest[upTo: 10])"
}

let digits = "0123456789"
let eol = (char("\r") *> char("\n")) | char(\Character.isNewline)
let ows = manyS(all: \Character.isWhitespace, !\Character.isNewline)
let sep: Character = ","
let dec = toDecimal <%> delimited(many1S(digits) + char(".") + many1S(digits))
let int = toInteger <%> delimited(many1S(digits))
let unquotation = manyS(all: !\Character.isNewline, !sep)
let qstr = CSValue.string <%> quotation
let ustr = CSValue.string <%> unquotation
let item = delimited(dec | int | qstr) | ustr | fail(csvError)
let empty = [CSValue]() <=> (ows <* peek(eol))
let row = empty | many(item, sepBy: char(sep))
let csv = many(row, sepBy: eol) <* eof

class ParsimoniousCSVTests: XCTestCase {

    func testCSV() {
        let rows = try! parse(rawCSV, with: csv)
        // 1001 includes the header row and the empty row at the end.
        // If I were writing a full CSV parser, I would exclude the blank
        // line at the end and do something more useful with the headers,
        // if present. But that's not what we're about here. Parser
        // combinators are not the place to do these things. Instead,
        // it should be done in a post-processing step.
        XCTAssertEqual(1001, rows.count)
        guard case .string(let name) = rows[934][1], name == "Elset" else {
            XCTFail("The value at rows[934][1] should be \"Elset\".")
            return
        }
    }
    
    func testCSVParserPerformance() {
        measure {
            _ = try! parse(rawCSV, with: csv)
        }
    }
    
}
