//
//  LookaheadTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct LookaheadTests {
  // MARK: - peek()

  @Test func peekOutputsWithoutConsuming() throws {
    let result = try char("a").peek().parse("ab")
    #expect(result.output == "a")
    #expect(result.input == "ab")
  }

  @Test func peekThenParse() throws {
    let result = try tuple(char("a").peek(), string("ab")).parse("ab!")
    #expect(result.output == ("a", "ab"))
    #expect(result.input == "!")
  }

  @Test func peekFailsWithInnerError() {
    let error = #expect(throws: ParseError<String>.self) {
      try char("a").peek().parse("b")
    }
    #expect(error?.reason == .nomatch)
    #expect(error?.message == "Expected \"a\".")
  }

  @Test func peekChoosesNextParser() throws {
    let object = string("{}")
    let array = string("[]")
    let value = char(anyOf: "{[").peek().flatMap { $0 == "{" ? object : array }
    #expect(try value.parse("{}").output == "{}")
    #expect(try value.parse("[]").output == "[]")
  }

  // MARK: - not()

  static let keyword = string("if") <* char(\.isLetter).not()

  @Test func notSucceedsWithoutConsuming() throws {
    let result = try char("a").not().parse("b")
    #expect(result.input == "b")
  }

  @Test func notFailsWhereParserSucceeds() {
    let error = #expect(throws: ParseError<String>.self) {
      try char("a").not().parse("a")
    }
    #expect(error?.reason == .nomatch)
    #expect(error.map { String($0.slice) } == "")
    #expect(error?.committed == false)
    #expect(error?.message == nil)
  }

  @Test func notSucceedsAtEnd() throws {
    _ = try char("a").not().parse("")
  }

  @Test func keywordBoundary() throws {
    let result = try Self.keyword.parse("if x")
    #expect(result.output == "if")
    #expect(result.input == " x")
    #expect(throws: ParseError<String>.self) {
      try Self.keyword.parse("iffy")
    }
  }

  @Test func notWithExpecting() {
    // Failing consumes nothing, so the error isn't committed and can be relabelled.
    let error = #expect(throws: ParseError<String>.self) {
      try char("a").not().expecting("Unexpected a.").parse("a")
    }
    #expect(error?.message == "Unexpected a.")
  }

  @Test func notFailureDoesNotCommit() throws {
    let p = char("a").not().commit1() <|> just(())
    _ = try p.parse("a")
  }

  @Test func notRethrowsCommittedError() {
    let error = #expect(throws: ParseError<String>.self) {
      try string("{x").commit1().not().parse("{y")
    }
    #expect(error?.committed == true)
    #expect(error?.message == "Expected \"{x\".")
  }

  @Test func uncommitNotTreatsCommittedErrorAsNoMatch() throws {
    let result = try string("{x").commit1().uncommit().not().parse("{y")
    #expect(result.input == "{y")
  }
}
