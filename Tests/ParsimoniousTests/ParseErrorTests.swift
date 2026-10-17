//
//  ParseErrorTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct ParseErrorTests {
  func error<Output>(
    _ parser: some Parsing<String, Output>,
    on input: Substring
  ) -> ParseError<String>? {
    #expect(throws: ParseError<String>.self) {
      try parser.parse(input)
    }
  }

  @Test func notConsumedOnFirstElement() {
    let input: Substring = "y"
    #expect(error(char("x"), on: input)?.consumed(relativeTo: input) == false)
  }

  @Test func consumedPartOfToken() {
    let input: Substring = "blab"
    #expect(error(string("blah"), on: input)?.consumed(relativeTo: input) == true)
  }

  @Test func consumedBeforeEndOfInput() {
    let input: Substring = "bl"
    #expect(error(string("blah"), on: input)?.consumed(relativeTo: input) == true)
  }

  @Test func notConsumedOnEmptyInput() {
    let input: Substring = ""
    #expect(error(char("a"), on: input)?.consumed(relativeTo: input) == false)
  }

  @Test func consumedIsRelativeToInput() {
    // Two characters were dropped first, so only the failing parser's progress counts.
    let input = "abX".dropFirst(2)
    #expect(error(char("c"), on: input)?.consumed(relativeTo: input) == false)
    let longer = "abcX".dropFirst(2)
    #expect(error(string("cd"), on: longer)?.consumed(relativeTo: longer) == true)
  }

  @Test func consumedIgnoresCommitment() {
    // `committed` and `consumed(relativeTo:)` are independent.
    let input: Substring = "y"
    let error = error(char("x").commit(), on: input)
    #expect(error?.committed == true)
    #expect(error?.consumed(relativeTo: input) == false)
  }
}
