//
//  ParsimoniousTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2/28/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

indirect enum JSON {
    case string(String)
    case number(NSNumber)
    case boolean(Bool)
    case object([String: JSON])
    case array([JSON])
    case null
}

// This does not handle escape sequences
let jstring = JSON.string <%> quotation

func jnumber(_ context: Context<String>) throws -> JSON {
    let digits = many1S("0123456789")
    let num = digits + optionalS(char(".") + digits)
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    let ns = try context <- num
    guard let n = formatter.number(from: ns) else {
        throw ParseError(context)
    }
    return .number(n)
}

func toBool(_ s: String) -> JSON {
    return .boolean(s == "true")
}

let jbool = toBool <%> string("true") | string("false")

let ws = manyS(\Character.isWhitespace)

func jarray(_ context: Context<String>) throws -> JSON {
    return try context <- JSON.array <%> char("[") *> ws *> many(json <* ws, sepBy: char(",") <*> ws) <* char("]")
}

func jpair(_ context: Context<String>) throws -> (key: String, value: JSON) {
    return try context.transact {
        let key = try context <- quotation
        try context <- ws + char(":") + ws
        let value = try context <- json
        return (key, value)
    }
}

func jobject(_ context: Context<String>) throws -> JSON {
    return try context.transact {
        try context <- char("{") <* ws
        let pairs = try context <- many(jpair <* ws, sepBy: ws + char(",") + ws)
        try context <- char("}")
        var object: [String: JSON] = [:]
        for pair in pairs {
            object[pair.key] = pair.value
        }
        return .object(object)
    }
}

let jnull = JSON.null <=> string("null")

func jsonError(_ rest: Substring?) -> String {
    guard let rest = rest else {
        return "Expected to match some JSON, but reached EOF."
    }
    return "Expected to match some JSON, but got garbage starting with \(rest[upTo: 20])."
}
let json = jnull | jstring | jnumber | jbool | jarray | jobject | fail(jsonError)

class ParsimoniousTests: XCTestCase {
    
    static let rawData: Data = rawJSON.data(using: .utf8)!

    func testJSONParser() {
        let result = try! parse(rawJSON, with: ws *> json <* ws)
        print(result)
    }
    
    func testJSONParserFailure() {
        let s = """
{"ok":~[7,
"""
        try XCTAssertThrowsError(parse(s, with: ws *> json <* ws))
    }
    
    func testJSONSerializationPerformance() {
        measure {
            _ = try! JSONSerialization.jsonObject(with: ParsimoniousTests.rawData, options: [])
        }
    }
    
    func testJSONParserPerformance() {
        measure {
            _ = try! parse(rawJSON, with: ws *> json <* ws)
        }
    }
    
}

