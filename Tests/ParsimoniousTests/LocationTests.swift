//
//  LocationTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct LocationTests {
  func location<Output>(
    of input: String,
    with parser: some Parsing<String, Output>
  ) -> (line: Int, column: Int)? {
    let error = #expect(throws: ParseError<String>.self) {
      try parse(input, with: parser)
    }
    return error?.location(in: input)
  }

  @Test func failsOnFirstCharacter() {
    #expect(location(of: "x", with: char("a")) ?? (0, 0) == (1, 1))
  }

  @Test func emptyInput() {
    #expect(location(of: "", with: char("a")) ?? (0, 0) == (1, 1))
  }

  @Test func sameLine() {
    // "ab" was consumed before the mismatch.
    #expect(location(of: "abc", with: string("abd")) ?? (0, 0) == (1, 3))
  }

  @Test func afterNewline() {
    #expect(location(of: "a\nbx", with: string("a\nby")) ?? (0, 0) == (2, 2))
  }

  @Test func crlfIsOneNewline() {
    #expect(location(of: "a\r\nbx", with: string("a\r\nby")) ?? (0, 0) == (2, 2))
  }

  @Test func otherNewlineCharacters() {
    // A lone carriage return and the Unicode line separator both start a new line.
    #expect(location(of: "a\rb\u{2028}cx", with: string("a\rb\u{2028}cy")) ?? (0, 0) == (3, 2))
  }

  @Test func endOfInput() {
    // An EOF error's slice runs to the end of the input.
    #expect(location(of: "ab", with: string("abc")) ?? (0, 0) == (1, 3))
  }

  @Test func endOfInputAfterTrailingNewline() {
    #expect(location(of: "ab\n", with: string("ab\nc")) ?? (0, 0) == (2, 1))
  }

  @Test func columnsCountCharacters() {
    // "e" plus a combining accent is one character, and so one column.
    #expect(location(of: "e\u{301}x", with: string("éy")) ?? (0, 0) == (1, 2))
  }

  @Test func committedErrorInsideNestedStructure() {
    let digit = char(anyOf: "0123456789")
    let list = digit.many(separatedBy: char(",").whitespaced()).whitespaced().bracketed().commit1()
    // The list backtracks out of ", x" and then expects "]" at the comma.
    #expect(location(of: "[1,\n 2,\n x]", with: list.end()) ?? (0, 0) == (2, 3))
  }

  @Test func characterArrayInput() {
    let input = Array("ab\ncx")
    let error = #expect(throws: ParseError<[Character]>.self) {
      try parse(input, with: string("ab\ncd"))
    }
    #expect(error?.location(in: input) ?? (0, 0) == (2, 2))
  }
}
