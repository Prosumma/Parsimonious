//
//  StringTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

import Parsimonious
import Testing

struct StringTests {
  struct Match: Sendable, CustomTestStringConvertible {
    let pattern: String
    let matching: CaseMatching
    let input: String
    let output: String
    let rest: String

    var testDescription: String { "\"\(pattern)\" (.\(matching)) on \"\(input)\"" }
  }

  struct Failure: Sendable, CustomTestStringConvertible {
    let pattern: String
    let matching: CaseMatching
    let input: String
    let reason: ParseError<String>.Reason
    let slice: String

    var testDescription: String { "\"\(pattern)\" (.\(matching)) on \"\(input)\"" }
  }

  @Test(arguments: [
    // Exact
    Match(pattern: "blah", matching: .exact, input: "blah", output: "blah", rest: ""),
    Match(pattern: "blah", matching: .exact, input: "blah!", output: "blah", rest: "!"),
    Match(pattern: "é", matching: .exact, input: "e\u{301}x", output: "e\u{301}", rest: "x"),
    // Simple
    Match(pattern: "blah", matching: .simple, input: "BLAH!", output: "BLAH", rest: "!"),
    Match(pattern: "BLAH", matching: .simple, input: "bLaH!", output: "bLaH", rest: "!"),
    Match(pattern: "é", matching: .simple, input: "É", output: "É", rest: ""),
    // Folded
    Match(pattern: "blah", matching: .folded, input: "bLAH!", output: "bLAH", rest: "!"),
    Match(
      pattern: "STRASSE", matching: .folded, input: "straße rest", output: "straße", rest: " rest"),
    Match(
      pattern: "straße", matching: .folded, input: "STRASSE rest", output: "STRASSE", rest: " rest"),
    Match(pattern: "ß", matching: .folded, input: "SS!", output: "SS", rest: "!"),
    // The empty pattern always matches without consuming.
    Match(pattern: "", matching: .exact, input: "abc", output: "", rest: "abc"),
    Match(pattern: "", matching: .simple, input: "abc", output: "", rest: "abc"),
    Match(pattern: "", matching: .folded, input: "abc", output: "", rest: "abc"),
    Match(pattern: "", matching: .folded, input: "", output: "", rest: ""),
  ])
  func matches(_ m: Match) throws {
    let result = try string(m.pattern, matching: m.matching).parse(m.input)
    #expect(result.output == m.output)
    #expect(result.input == m.rest[...])
  }

  @Test(arguments: [
    // Exact
    Failure(
      pattern: "blah", matching: .exact, input: "blab and more", reason: .nomatch, slice: "bla"),
    Failure(pattern: "blah", matching: .exact, input: "BLAH", reason: .nomatch, slice: ""),
    Failure(pattern: "blah", matching: .exact, input: "bla", reason: .eof, slice: "bla"),
    Failure(pattern: "blah", matching: .exact, input: "", reason: .eof, slice: ""),
    // Simple
    Failure(
      pattern: "STRASSE", matching: .simple, input: "straße", reason: .nomatch, slice: "stra"),
    Failure(pattern: "I", matching: .simple, input: "ı", reason: .nomatch, slice: ""),
    Failure(pattern: "blah", matching: .simple, input: "BLA", reason: .eof, slice: "BLA"),
    // Folded
    Failure(pattern: "STRASSE", matching: .folded, input: "stra", reason: .eof, slice: "stra"),
    Failure(pattern: "STRASSE", matching: .folded, input: "STRAß", reason: .eof, slice: "STRAß"),
    Failure(
      pattern: "STRASSE", matching: .folded, input: "strz and more", reason: .nomatch, slice: "str"),
    Failure(pattern: "I", matching: .folded, input: "ı", reason: .nomatch, slice: ""),
    Failure(pattern: "x", matching: .folded, input: "", reason: .eof, slice: ""),
  ])
  func fails(_ f: Failure) {
    let error = #expect(throws: ParseError<String>.self) {
      try string(f.pattern, matching: f.matching).parse(f.input)
    }
    #expect(error?.reason == f.reason)
    #expect(error.map { String($0.slice) } == f.slice)
    #expect(error?.message == "Expected \"\(f.pattern)\".")
  }

  @Test func defaultsToExact() {
    #expect(throws: ParseError<String>.self) {
      try string("blah").parse("BLAH")
    }
  }

  @Test func consumesForNextParser() throws {
    let result = try chain(string("ab"), string("CD", matching: .simple)).parse("abcd!")
    #expect(result.output == ["ab", "cd"])
    #expect(result.input == "!")
  }

  @Test func infersStringInputWithoutContext() {
    let blah = string("blah")
    #expect(type(of: blah) == Parser<String, String>.self)
  }

  @Test(arguments: [CaseMatching.exact, .simple, .folded])
  func characterArrayInput(_ matching: CaseMatching) throws {
    let input: [Character] = Array("blah!")
    let result = try string("blah", matching: matching).parse(input)
    #expect(result.output == "blah")
    #expect(Array(result.input) == ["!"])
  }

  @Test func substringInput() throws {
    let input: Substring = "xxSTRASSE!".dropFirst(2)
    let result = try string("straße", matching: .folded).parse(input)
    #expect(result.output == "STRASSE")
    #expect(result.input == "!")
  }

  @Test func foldedSpansSeparateCombiningMark() throws {
    // As separate Characters, "e" and U+0301 merge into "é" once joined into a String,
    // so the end of a folded match must be mapped back by scalars, not characters.
    let input: [Character] = ["e", "\u{301}", "x"]
    let result = try string("É", matching: .folded).parse(input)
    #expect(result.output == "e\u{301}")
    #expect(Array(result.input) == ["x"])
  }

  @Test func errorSliceStartsAtToken() {
    let input = "xxblab"
    let error = #expect(throws: ParseError<String>.self) {
      try chain(string("xx"), string("blah")).parse(input)
    }
    #expect(error.map { String($0.slice) } == "bla")
    #expect(error?.slice.startIndex == input.index(input.startIndex, offsetBy: 2))
  }
}
