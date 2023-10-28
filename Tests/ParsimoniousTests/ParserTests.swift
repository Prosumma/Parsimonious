//
//  ParserTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2023-10-22.
//

import Parsimonious
import XCTest

typealias RSParser = Parser<String, (Range<String.Index>, String)>

class ParserTests: XCTestCase {
  func testWithRange() throws {
    // Given
    let word: RSParser = char(^\Character.isLetter)+.withRange()
    let sep: SParser = char(",")
    let parser = many1(word, separator: sep) <* eof()
    let input = "aaa,bbb"

    // When
    let output = try parse(input, with: parser)

    // Then
    for (r, s) in output {
      XCTAssertEqual(String(input[r]), s)
    }
  }
}
