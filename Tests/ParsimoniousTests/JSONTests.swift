//
//  CombinatorTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2023-10-20.
//

import XCTest

import Iatheto
@testable import Parsimonious

/*
 What you see below is a complete JSON parser.
 Is it fully compliant with RFC 8259? As far as I can
 tell, yes.

 In general, you should not parse JSON with 
 parser combinators, as fun as it may be to write
 them. It's just too slow compared to dedicated,
 low-level parsers like Apple's `JSONDecoder`.

 But building a JSON parser is a great way to
 give your parser combinator package a workout.
 */

typealias SParser = Parser<String, String>
typealias JParser = Parser<String, JSON>

// Strings
let escapedString: SParser = manyS((char("\\") + char("\"")) <|> char(not("\"")))
let unescapedString = escapedString >>> JSON.unescape
let quotedString = doubleStraightQuoted(unescapedString)
let jstring = quotedString >>> JSON.string

// Numbers
enum NumberError: Error {
  case invalidNumber(String)
}
var decimalNumberFormatter: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  return formatter
}()
func decimal(from string: String) throws -> Decimal {
  guard let decimal = decimalNumberFormatter.number(from: string)?.decimalValue else {
    throw NumberError.invalidNumber(string)
  }
  return decimal
}
let natural: SParser = char(any: "123456789")
let digit: SParser = char(any: "0123456789")
let sign: SParser = optional(char("-"))
let integer = "0" <|> (natural + digit*)
let fraction = "." + natural+
let exponent = char(any: "eE") + optional(char(any: "+-")) + digit+
let jnumber = (sign + integer + optional(fraction) + optional(exponent)) >>> decimal(from:) >>> JSON.number

// Bools
let jbool: JParser = (string("true") <|> string("false")) >>> { s in s == "true" } >>> JSON.bool

// Null
let jnull: JParser = string("null") *>> JSON.null

// Object
var assignment: Parser<String, (String, JSON)> {
  tuple(whitespacedWithNewlines(quotedString) <* ":", json)
}
let assignments = many(assignment, separator: ",") >>> { Dictionary($0, uniquingKeysWith: { _, v2 in v2 }) }
let jobject = braced(assignments) >>> JSON.object

// Array
var jarray: JParser {
  bracketed(many(json, separator: ",")) >>> JSON.array
}

// JSON
let json = whitespacedWithNewlines(jstring <|> jnumber <|> jobject <|> jarray <|> jbool <|> jnull)

final class JSONTests: XCTestCase {
  func testJSON() throws {
    // Given
    guard let path = Bundle.module.path(forResource: "JSON", ofType: "json") else {
      return XCTFail("Couldn't load JSON.json resource.")
    }
    let input = try String(contentsOfFile: path)

    // When
    let output = try parse(input, with: json <* eof())

    // Then
    XCTAssertEqual(output["complexObject"]?["array"]?[1], 2)
    XCTAssertEqual(output["array"]?[4], 3.14)
  }
}
