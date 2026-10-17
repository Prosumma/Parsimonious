//
//  ScalarTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct ScalarTests {
  // MARK: - scalar(_:)

  @Test func matchesScalar() throws {
    let result = try scalar("a").parse("ab")
    #expect(result.output == "a")
    #expect(result.input == "b")
  }

  @Test func failsOnMismatch() {
    let error = #expect(throws: ParseError<String>.self) {
      try scalar("a").parse("b")
    }
    #expect(error?.reason == .nomatch)
    #expect(error?.message == "Expected \"a\".")
    #expect(error.map { String($0.slice) } == "")
  }

  @Test func failsAtEnd() {
    let error = #expect(throws: ParseError<String>.self) {
      try scalar("a").parse("")
    }
    #expect(error?.reason == .eof)
  }

  @Test func consumesOneScalarOfACharacter() throws {
    // A quote followed by a combining mark is one Character, which `char` can't match.
    let input = "\"\u{301}x"
    #expect(throws: ParseError<String>.self) {
      try char("\"").parse(input)
    }
    let result = try scalar("\"").parse(input)
    #expect(result.output == "\"")
    #expect(result.input == "\u{301}x")
    #expect(result.input.count == 2)
  }

  @Test func invisibleScalarsAreNamedByCodePoint() {
    let messages = ["\u{301}", " ", "\t", "\u{200B}"].map { s in
      let error = #expect(throws: ParseError<String>.self) {
        try scalar(s.unicodeScalars.first!).parse("x")
      }
      return error?.message
    }
    #expect(messages == ["Expected U+0301.", "Expected U+0020.", "Expected U+0009.", "Expected U+200B."])
  }

  @Test func notCanonicallyEquivalent() throws {
    // Unlike `char`, a precomposed é doesn't match e followed by U+0301.
    #expect(throws: ParseError<String>.self) {
      try scalar("\u{E9}").parse("e\u{301}")
    }
    #expect(try char("\u{E9}").parse("e\u{301}").output == "e\u{301}")
  }

  // MARK: - scalar(anyOf:)

  @Test func anyOfMatches() throws {
    let marks = scalar(anyOf: "\u{301}\u{303}")
    #expect(try marks.parse("\u{303}").output == "\u{303}")
  }

  @Test func anyOfMessageListsScalars() {
    let error = #expect(throws: ParseError<String>.self) {
      try scalar(anyOf: "ab\u{301}").parse("x")
    }
    #expect(error?.message == "Expected one of \"a\", \"b\", U+0301.")
  }

  @Test func anyOfEmptyNeverMatches() {
    #expect(throws: ParseError<String>.self) {
      try scalar(anyOf: "").parse("a")
    }
  }

  @Test func anyOfSplitsChoicesIntoScalars() throws {
    // "\r\n" in the choices is two scalars, so each matches on its own.
    let newline = scalar(anyOf: "\r\n")
    let result = try newline.parse("\n\r")
    #expect(result.output == "\n")
    #expect(result.input == "\r")
  }

  // MARK: - scalar(not:)

  @Test func notMatchesOthers() throws {
    #expect(try scalar(not: "\"").parse("a").output == "a")
  }

  @Test func notRejects() {
    let error = #expect(throws: ParseError<String>.self) {
      try scalar(not: "\"").parse("\"")
    }
    #expect(error?.message == "Expected any scalar except \"\"\".")
  }

  @Test func notFailsAtEnd() {
    let error = #expect(throws: ParseError<String>.self) {
      try scalar(not: "\"").parse("")
    }
    #expect(error?.reason == .eof)
  }

  // MARK: - Key paths and predicates

  @Test func keyPath() throws {
    let marks = scalar(\.properties.isDiacritic)+.toString()
    let result = try (scalar("a") *> marks).parse("a\u{303}\u{301}b")
    #expect(result.output == "\u{303}\u{301}")
    #expect(result.input == "b")
  }

  @Test func keyPathHasNoMessage() {
    let error = #expect(throws: ParseError<String>.self) {
      try scalar(\.properties.isDiacritic).parse("a")
    }
    #expect(error?.message == nil)
  }

  @Test func notKeyPath() throws {
    let result = try scalar(not: \.properties.isWhitespace)+.toString().parse("ab c")
    #expect(result.output == "ab")
  }

  @Test func predicate() throws {
    let result = try scalar(where: \.isASCII)+.toString().parse("abé")
    #expect(result.output == "ab")
    #expect(result.input == "é")
  }

  // MARK: - toString()

  @Test func toStringJoinsScalarsIntoCharacters() throws {
    let letters = scalar(\.properties.isAlphabetic) <|> scalar(\.properties.isDiacritic)
    let result = try letters+.toString().parse("e\u{301}a")
    #expect(result.output == "éa")
    #expect(result.output.count == 2)
  }

  @Test func singleScalarToString() throws {
    #expect(try scalar("a").toString().parse("a").output == "a")
  }

  // MARK: - Mixing with char and string

  @Test func charSeesRestOfGraphemeAsNewCharacter() throws {
    let p = tuple(scalar("a"), char("\u{301}"), string("bc"))
    let result = try p.parse("a\u{301}bc")
    #expect(result.output == ("a", "\u{301}", "bc"))
  }

  @Test func locationInsideGrapheme() {
    // The error is between "a" and U+0301, which make one Character.
    let input = "x\na\u{301}b"
    let error = #expect(throws: ParseError<String>.self) {
      try (string("x\n") *> scalar("a") *> char("z")).parse(input)
    }
    #expect(error?.location(in: input) ?? (0, 0) == (2, 2))
  }

  // MARK: - Inference

  @Test func infersStringInputWithoutContext() {
    #expect(type(of: scalar("a")) == Parser<String, Unicode.Scalar>.self)
    #expect(type(of: scalar(anyOf: "ab")) == Parser<String, Unicode.Scalar>.self)
    #expect(type(of: scalar(not: "a")) == Parser<String, Unicode.Scalar>.self)
    #expect(type(of: scalar(\.isASCII)) == Parser<String, Unicode.Scalar>.self)
    #expect(type(of: scalar(not: \.isASCII)) == Parser<String, Unicode.Scalar>.self)
    #expect(type(of: scalar(where: { _ in true })) == Parser<String, Unicode.Scalar>.self)
  }

  @Test func substringInput() throws {
    let p: Parser<Substring, Unicode.Scalar> = scalar("\"")
    let result = try p.parse(Substring("\"\u{301}"))
    #expect(result.output == "\"")
    #expect(result.input == "\u{301}")
  }
}
