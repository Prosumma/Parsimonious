//
//  WhitespaceTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct WhitespaceTests {
  static let whitespace = Parsers<String>.whitespace

  @Test(arguments: [
    " ", "\t", "\n", "\r", "\r\n",
    "\u{A0}",  // no-break space
    "\u{2028}",  // line separator
    "\u{3000}",  // ideographic space
  ])
  func matchesWhitespace(_ ws: String) throws {
    let result = try Self.whitespace.parse(ws + "x")
    #expect(result.output == Character(ws))
    #expect(result.input == "x")
  }

  @Test(arguments: [
    " \u{303}",  // space + combining tilde
    "\u{A0}\u{301}",  // no-break space + combining acute
    "\u{2003}\u{301}",  // em space + combining acute
  ])
  func rejectsWhitespaceWithCombiningMark(_ input: String) {
    // Each is a single Character whose first scalar is whitespace.
    #expect(input.count == 1)
    #expect(Character(input).isWhitespace)
    let error = #expect(throws: ParseError<String>.self) {
      try Self.whitespace.parse(input)
    }
    #expect(error?.reason == .nomatch)
  }

  @Test func rejectsNonWhitespace() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.whitespace.parse("x")
    }
    #expect(error?.reason == .nomatch)
    #expect(error?.message == "Expected whitespace.")
  }

  @Test func failsAtEnd() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.whitespace.parse("")
    }
    #expect(error?.reason == .eof)
    #expect(error?.message == "Expected whitespace.")
  }

  @Test func keyPathCharIsFirstScalarOnly() throws {
    // `char(\.isWhitespace)` is unchanged, and still consumes the mark.
    let result = try char(\.isWhitespace).parse(" \u{303}x")
    #expect(result.output == " \u{303}")
    #expect(result.input == "x")
  }

  // MARK: - whitespaced()

  @Test func whitespacedKeepsCombiningMark() throws {
    let result = try char(">").whitespaced().parse("> \u{303}")
    #expect(result.output == ">")
    #expect(result.input == " \u{303}")
  }

  @Test func soundChangeRule() throws {
    // A rule ending in a diacritic written on its own, Unicode's way, with a space before it.
    let rule = tuple(char("V"), char(">").whitespaced() *> char(\.isWhitespace))
    let result = try rule.parse("V > \u{303}")
    #expect(result.output == ("V", " \u{303}"))
    #expect(result.input.isEmpty)
  }

  @Test func whitespacedConsumesCRLF() throws {
    let result = try char("x").whitespaced().parse("\r\n x\r\n\ty")
    #expect(result.output == "x")
    #expect(result.input == "y")
  }

  @Test func whitespaced1RequiresWhitespace() {
    #expect(throws: ParseError<String>.self) {
      try char("x").whitespaced1().parse(" \u{303}x ")
    }
  }

  @Test func characterArrayInput() throws {
    let input = Array("  x \u{303}")
    let result = try char("x").whitespaced().parse(input)
    #expect(result.output == "x")
    #expect(Array(result.input) == [" \u{303}"])
  }
}
