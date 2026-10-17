//
//  DelimiterTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct DelimiterTests {
  static let word = char(\.isLetter)+.toString()
  // Content that starts with a lone combining mark, as a Character of its own.
  static let marked = join(scalar(\.properties.isDiacritic).array(), scalar(\.properties.isAlphabetic)*).toString()

  // MARK: - Scalar overloads

  @Test func precededBy() throws {
    let result = try Self.word.preceded(by: "$").parse("$abc!")
    #expect(result.output == "abc")
    #expect(result.input == "!")
  }

  @Test func followedBy() throws {
    let result = try Self.word.followed(by: ";").parse("abc;!")
    #expect(result.output == "abc")
    #expect(result.input == "!")
  }

  @Test func delimitedBy() throws {
    let result = try Self.word.delimited(by: "|").parse("|abc|!")
    #expect(result.output == "abc")
    #expect(result.input == "!")
  }

  @Test func delimitedByAnd() throws {
    let result = try Self.word.delimited(by: "<", and: ">").parse("<abc>!")
    #expect(result.output == "abc")
    #expect(result.input == "!")
  }

  @Test func missingDelimiterMessage() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.word.delimited(by: "<", and: ">").parse("<abc")
    }
    #expect(error?.reason == .eof)
    #expect(error?.message == "Expected \">\".")
  }

  // MARK: - Combining marks after a delimiter

  @Test func openingDelimiterBeforeMark() throws {
    // "<" and U+0301 are one Character, but the delimiter is matched as a scalar.
    let result = try Self.marked.delimited(by: "<", and: ">").parse("<\u{301}a>")
    #expect(result.output == "\u{301}a")
    #expect(result.input.isEmpty)
  }

  @Test func closingDelimiterBeforeMark() throws {
    let result = try Self.word.followed(by: ";").parse("abc;\u{301}")
    #expect(result.output == "abc")
    #expect(result.input == "\u{301}")
  }

  @Test func precededByBeforeMark() throws {
    let result = try Self.marked.preceded(by: "$").parse("$\u{303}")
    #expect(result.output == "\u{303}")
  }

  // MARK: - Named delimiters

  @Test(arguments: [
    ("'\u{301}a'", "\u{301}a"),
    ("'a'", "a"),
  ])
  func singleStraightQuoted(_ input: String, _ expected: String) throws {
    let content = scalar(not: "'")*.toString()
    #expect(try content.singleStraightQuoted().parse(input).output == expected)
  }

  @Test func doubleStraightQuoted() throws {
    let content = scalar(not: "\"")*.toString()
    #expect(try content.doubleStraightQuoted().parse("\"\u{301}abc\"").output == "\u{301}abc")
    #expect(try content.doubleStraightQuoted().parse("\"\"").output == "")
  }

  @Test func parenthesized() throws {
    #expect(try Self.marked.parenthesized().parse("(\u{301})").output == "\u{301}")
  }

  @Test func bracketed() throws {
    #expect(try Self.marked.bracketed().parse("[\u{301}]").output == "\u{301}")
  }

  @Test func braced() throws {
    #expect(try Self.marked.braced().parse("{\u{301}}").output == "\u{301}")
  }

  @Test func namedDelimiterMessages() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.word.braced().parse("(abc)")
    }
    #expect(error?.message == "Expected \"{\".")
  }

  // MARK: - Input types

  @Test func substringInput() throws {
    let p: Parser<Substring, String> = char(\.isLetter)+.toString().bracketed()
    #expect(try p.parse(Substring("[abc]")).output == "abc")
  }

  @Test func whitespacedStillWorksOnCharacterArrays() throws {
    let result = try char("x").whitespaced().parse(Array(" x "))
    #expect(result.output == "x")
    #expect(result.input.isEmpty)
  }
}
