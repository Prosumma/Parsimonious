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
    let index = string.index(string.startIndex, offsetBy: 3)
    let state = ParseState<String, String>(
      output: "foo",
      index: index
    )

    // When
    let newState = state.flatMap { _, range in .init(output: "bar", index: index) }

    // Then
    XCTAssertEqual(newState.output, "bar")
    XCTAssertEqual(newState.index, index)
  }
}
