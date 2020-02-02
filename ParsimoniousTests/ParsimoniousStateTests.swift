//
//  ParsimoniousStateTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 8/23/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

enum Datum {
    case integer(Int)
    case string(String)
}

func datum(_ context: Context<String>) throws -> Datum {
    func integer(_ context: Context<String>) throws -> Datum {
        return try context.transact {
            let s = try context <- many1S("0123456789")
            guard let i = Int(s) else {
                throw ParseError(message: "'\(s)' out of range for integer.", context: context, inner: ErrorCode.unexpected)
            }
            context["integers"] = (context["integers"]! as! Int) + 1
            return .integer(i)
        }
    }
    let string = Datum.string <%> quotation
    let datum = try context <- integer | string | fail("Expected to match an integer or a quoted string.")
    return datum
}

func data(_ context: Context<String>) throws -> ([Datum], Int) {
    let ws = manyS(\Character.isWhitespace)
    context["integers"] = 0
    let data = try context <- (many(datum, sepBy: char(",") <*> ws) <*> ws) <* eof
    return (data, context["integers"]! as! Int)
}

class ParsimoniousContextTests: XCTestCase {
    func testContextState() {
        let s = "\"ok\", 79, 44, \"never\", 8   "
        let (result, integerCount) = try! parse(s, with: data)
        XCTAssertEqual(integerCount, 3)
        print(result)
    }
}
