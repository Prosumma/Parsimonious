//
//  RepetitionTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct RepetitionTests {
  static let hex = char(\.isHexDigit)

  // MARK: - count(_:)

  @Test func countMatchesExactly() throws {
    let result = try Self.hex.count(4).toString().parse("00a1x")
    #expect(result.output == "00a1")
    #expect(result.input == "x")
  }

  @Test func countStopsAtLimit() throws {
    // There are more hex digits, but only four are taken.
    let result = try Self.hex.count(4).toString().parse("00a1ff")
    #expect(result.output == "00a1")
    #expect(result.input == "ff")
  }

  @Test func countFailsOnShortMatch() {
    let input = "00x1"
    let error = #expect(throws: ParseError<String>.self) {
      try Self.hex.count(4).parse(input)
    }
    #expect(error?.reason == .nomatch)
    #expect(error.map { input.distance(from: input.startIndex, to: $0.slice.endIndex) } == 2)
  }

  @Test func countFailsAtEnd() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.hex.count(4).parse("00")
    }
    #expect(error?.reason == .eof)
  }

  @Test func countZero() throws {
    let result = try Self.hex.count(0).parse("00")
    #expect(result.output.isEmpty)
    #expect(result.input == "00")
  }

  @Test func countRepeatsZeroWidthParser() throws {
    // The loop is bounded, so a parser that consumes nothing just repeats.
    let result = try just("z").count(3).parse("x")
    #expect(result.output == ["z", "z", "z"])
    #expect(result.input == "x")
  }

  @Test func countFailureCommitsUnderCommit1() {
    // Two digits were consumed before the failure, so the error is committed.
    let p = Self.hex.count(4).toString().commit1() <|> just("fallback")
    let error = #expect(throws: ParseError<String>.self) {
      try p.parse("00x1")
    }
    #expect(error?.committed == true)
  }

  @Test func unicodeEscape() throws {
    let escape = string("\\u") *> Self.hex.count(4).toString()
    #expect(try escape.parse("\\u00e9").output == "00e9")
  }

  // MARK: - count(upTo:)

  @Test func countUpToStopsAtLimit() throws {
    let result = try char(\.isLetter).count(upTo: 3).toString().parse("abcd")
    #expect(result.output == "abc")
    #expect(result.input == "d")
  }

  @Test func countUpToStopsEarly() throws {
    let result = try char(\.isLetter).count(upTo: 3).toString().parse("ab1")
    #expect(result.output == "ab")
    #expect(result.input == "1")
  }

  @Test func countUpToMatchesNothing() throws {
    let result = try char(\.isLetter).count(upTo: 3).parse("123")
    #expect(result.output.isEmpty)
    #expect(result.input == "123")
  }

  @Test func countUpToStopsOnZeroWidth() throws {
    let result = try just("z").count(upTo: 3).parse("x")
    #expect(result.output.isEmpty)
  }

  @Test func countUpToRethrowsCommittedError() {
    let pair = string("ab").commit1()
    let error = #expect(throws: ParseError<String>.self) {
      try pair.count(upTo: 3).parse("abax")
    }
    #expect(error?.committed == true)
    #expect(error?.message == "Expected \"ab\".")
  }

  // MARK: - optional()

  static let signed = join(char(anyOf: "+-").optional(), char(\.isNumber)+).toString()

  @Test func optionalPresent() throws {
    #expect(try Self.signed.parse("-42").output == "-42")
  }

  @Test func optionalAbsent() throws {
    let result = try Self.signed.parse("42!")
    #expect(result.output == "42")
    #expect(result.input == "!")
  }

  @Test func optionalOutputs() throws {
    #expect(try char("a").optional().parse("ab").output == ["a"])
    #expect(try char("a").optional().parse("b").output == [])
  }

  @Test func optionalBacktracksPartialMatch() throws {
    // `string("ab")` consumes "a" before failing, but the failure isn't committed.
    let result = try string("ab").optional().parse("ax")
    #expect(result.output == [])
    #expect(result.input == "ax")
  }

  @Test func optionalRethrowsCommittedError() {
    let error = #expect(throws: ParseError<String>.self) {
      try string("ab").commit1().optional().parse("ax")
    }
    #expect(error?.committed == true)
  }
}
