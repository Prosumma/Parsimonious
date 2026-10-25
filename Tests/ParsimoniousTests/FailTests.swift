//
//  FailTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-25.
//

import Parsimonious
import Testing

struct FailTests {
  @Test func failsWithMessage() {
    let parser: Parser<String, Character> = fail("Nope.")
    let error = #expect(throws: ParseError<String>.self) {
      try parse("abc", with: parser)
    }
    #expect(error?.message == "Nope.")
    #expect(error?.reason == .nomatch)
    #expect(error?.committed == false)
    #expect(error?.slice.isEmpty == true)
  }

  @Test func failsAtEndOfInput() {
    let parser: Parser<String, Character> = fail("Nope.")
    let error = #expect(throws: ParseError<String>.self) {
      try parse("", with: parser)
    }
    #expect(error?.message == "Nope.")
  }

  @Test func reportsWhereItWasReached() {
    let parser = string("ab") *> (fail("Nope.") as Parser<String, Character>)
    let error = #expect(throws: ParseError<String>.self) {
      try parse("abc", with: parser)
    }
    #expect(error.map { $0.location(in: "abc") } ?? (0, 0) == (1, 3))
  }

  @Test func uncommittedFailureBacktracks() throws {
    let parser = fail("Nope.") <|> char("a")
    #expect(try parse("a", with: parser) == "a")
  }

  @Test func namesARecognizedMistake() throws {
    let digit = char(anyOf: "0123456789")
    let close = char(")") <|> (char(",").peek() *> fail("Trailing commas aren't allowed.").commit())
    let list = digit.many1(separatedBy: char(",")).preceded(by: char("(")) <* close

    #expect(try parse("(1,2)", with: list) == ["1", "2"])
    let error = #expect(throws: ParseError<String>.self) {
      try parse("(1,2,)", with: list)
    }
    #expect(error?.message == "Trailing commas aren't allowed.")
    #expect(error.map { $0.location(in: "(1,2,)") } ?? (0, 0) == (1, 5))
  }

  @Test func committedMessageSurvivesExpecting() {
    let parser =
      (char("x").peek() *> (fail("No x here.") as Parser<String, Character>).commit())
      <|> char("a")
    let error = #expect(throws: ParseError<String>.self) {
      try parse("x", with: parser.expecting("Expected a."))
    }
    #expect(error?.message == "No x here.")
  }
}
