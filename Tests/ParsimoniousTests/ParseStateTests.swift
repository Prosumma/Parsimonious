//
//  ParseStateTests.swift
//  ParsimoniousTests
//
//  Created by Greg Higley on 2023-10-22.
//

import Parsimonious
import XCTest

class ParseStateTests: XCTestCase {
  func testParseState() {
    // Given
    let string = "foobar"
    let range = string.startIndex..<string.index(string.startIndex, offsetBy: 3)
    let state = ParseState<String, String>(
      output: "foo",
      range: range
    )
    
    // When
    let newState = state.flatMap { _, range in .init(output: "bar", range: range) }
    
    // Then
    XCTAssertEqual(newState.output, "bar")
    XCTAssertEqual(newState.range, range)
  }
}
