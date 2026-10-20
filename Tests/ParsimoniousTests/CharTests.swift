//
//  CharTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-06.
//

import Parsimonious
import Testing

struct CharTests {
  struct Match: Sendable, CustomTestStringConvertible {
    let ch: Character
    let matching: CaseMatching
    let input: String
    let output: Character

    var testDescription: String { "\"\(ch)\" (.\(matching)) on \"\(input)\"" }
  }

  struct Failure: Sendable, CustomTestStringConvertible {
    let ch: Character
    let matching: CaseMatching
    let input: String
    let reason: ParseError<String>.Reason
    let slice: String

    var testDescription: String { "\"\(ch)\" (.\(matching)) on \"\(input)\"" }
  }

  @Test(arguments: [
    // Exact
    Match(ch: "a", matching: .exact, input: "abc", output: "a"),
    Match(ch: "é", matching: .exact, input: "e\u{301}x", output: "e\u{301}"),
    // Simple
    Match(ch: "a", matching: .simple, input: "Abc", output: "A"),
    Match(ch: "A", matching: .simple, input: "abc", output: "a"),
    Match(ch: "é", matching: .simple, input: "É", output: "É"),
    Match(ch: "ß", matching: .simple, input: "ẞ", output: "ẞ"),
    // Folded
    Match(ch: "a", matching: .folded, input: "Abc", output: "A"),
    Match(ch: "σ", matching: .folded, input: "ς", output: "ς"),
    Match(ch: "ß", matching: .folded, input: "ẞ", output: "ẞ"),
  ])
  func matches(_ m: Match) throws {
    let result = try char(m.ch, matching: m.matching).parse(m.input)
    #expect(result.output == m.output)
    #expect(result.input == m.input.dropFirst())
  }

  @Test(arguments: [
    // Exact
    Failure(ch: "a", matching: .exact, input: "A", reason: .nomatch, slice: ""),
    Failure(ch: "a", matching: .exact, input: "bcd", reason: .nomatch, slice: ""),
    // Simple
    Failure(ch: "σ", matching: .simple, input: "ς", reason: .nomatch, slice: ""),
    Failure(ch: "I", matching: .simple, input: "ı", reason: .nomatch, slice: ""),
    // Folded never consumes more than one character.
    Failure(ch: "ß", matching: .folded, input: "ss", reason: .nomatch, slice: ""),
    Failure(ch: "I", matching: .folded, input: "ı", reason: .nomatch, slice: ""),
    // End of input
    Failure(ch: "a", matching: .exact, input: "", reason: .eof, slice: ""),
    Failure(ch: "a", matching: .simple, input: "", reason: .eof, slice: ""),
    Failure(ch: "a", matching: .folded, input: "", reason: .eof, slice: ""),
  ])
  func fails(_ f: Failure) {
    let error = #expect(throws: ParseError<String>.self) {
      try char(f.ch, matching: f.matching).parse(f.input)
    }
    #expect(error?.reason == f.reason)
    #expect(error.map { String($0.slice) } == f.slice)
    #expect(error?.message == "Expected \"\(f.ch)\".")
  }

  @Test func defaultsToExact() {
    let p: Parser<String, Character> = char("a")
    #expect(throws: ParseError<String>.self) {
      try p.parse("A")
    }
  }

  @Test func infersStringInputWithoutContext() {
    let a = char("a")
    #expect(type(of: a) == Parser<String, Character>.self)
  }

  @Test func characterArrayInput() throws {
    let input: [Character] = ["X", "y"]
    let result = try char("x", matching: .simple).parse(input)
    #expect(result.output == "X")
    #expect(Array(result.input) == ["y"])
  }

  // MARK: - char(anyOf:)

  struct AnyOfMatch: Sendable, CustomTestStringConvertible {
    let choices: String
    let matching: CaseMatching
    let input: String
    let output: Character

    var testDescription: String { "anyOf \"\(choices)\" (.\(matching)) on \"\(input)\"" }
  }

  struct AnyOfFailure: Sendable, CustomTestStringConvertible {
    let choices: String
    let matching: CaseMatching
    let input: String
    let reason: ParseError<String>.Reason
    let slice: String

    var testDescription: String { "anyOf \"\(choices)\" (.\(matching)) on \"\(input)\"" }
  }

  @Test(arguments: [
    AnyOfMatch(choices: "aeiou", matching: .exact, input: "e!", output: "e"),
    AnyOfMatch(choices: "aeiou", matching: .exact, input: "u!", output: "u"),
    AnyOfMatch(choices: "aeiou", matching: .simple, input: "E!", output: "E"),
    AnyOfMatch(choices: "ασ", matching: .folded, input: "ς!", output: "ς"),
  ])
  func anyOfMatches(_ m: AnyOfMatch) throws {
    let result = try char(anyOf: m.choices, matching: m.matching).parse(m.input)
    #expect(result.output == m.output)
    #expect(result.input == "!")
  }

  @Test(arguments: [
    AnyOfFailure(choices: "aeiou", matching: .exact, input: "E", reason: .nomatch, slice: ""),
    AnyOfFailure(
      choices: "aeiou", matching: .exact, input: "xyz and the rest", reason: .nomatch, slice: ""),
    AnyOfFailure(choices: "ıo", matching: .simple, input: "I", reason: .nomatch, slice: ""),
    AnyOfFailure(choices: "ασ", matching: .simple, input: "ς", reason: .nomatch, slice: ""),
    AnyOfFailure(choices: "aeiou", matching: .exact, input: "", reason: .eof, slice: ""),
    AnyOfFailure(choices: "aeiou", matching: .folded, input: "", reason: .eof, slice: ""),
  ])
  func anyOfFails(_ f: AnyOfFailure) {
    let error = #expect(throws: ParseError<String>.self) {
      try char(anyOf: f.choices, matching: f.matching).parse(f.input)
    }
    #expect(error?.reason == f.reason)
    #expect(error.map { String($0.slice) } == f.slice)
    #expect(error?.message == "Expected one of \"\(f.choices)\".")
  }

  @Test func anyOfEmptyNeverMatches() {
    let error = #expect(throws: ParseError<String>.self) {
      try char(anyOf: "").parse("a")
    }
    #expect(error?.reason == .nomatch)
  }

  @Test func anyOfInfersStringInputWithoutContext() {
    let vowel = char(anyOf: "aeiou")
    #expect(type(of: vowel) == Parser<String, Character>.self)
  }

  @Test func anyOfCharacterArrayInput() throws {
    let input: [Character] = ["O", "k"]
    let result = try char(anyOf: "aeiou", matching: .simple).parse(input)
    #expect(result.output == "O")
    #expect(Array(result.input) == ["k"])
  }

  // MARK: - char(not:)

  @Test(arguments: [
    // Exact
    Match(ch: "a", matching: .exact, input: "b!", output: "b"),
    Match(ch: "a", matching: .exact, input: "A!", output: "A"),
    // Simple
    Match(ch: "a", matching: .simple, input: "b!", output: "b"),
    Match(ch: "I", matching: .simple, input: "ı!", output: "ı"),
    // Folded never matches more than one character.
    Match(ch: "ß", matching: .folded, input: "s!", output: "s"),
  ])
  func notMatches(_ m: Match) throws {
    let result = try char(not: m.ch, matching: m.matching).parse(m.input)
    #expect(result.output == m.output)
    #expect(result.input == "!")
  }

  @Test(arguments: [
    // Exact
    Failure(ch: "a", matching: .exact, input: "abc", reason: .nomatch, slice: ""),
    // Simple
    Failure(ch: "a", matching: .simple, input: "A", reason: .nomatch, slice: ""),
    Failure(ch: "A", matching: .simple, input: "a", reason: .nomatch, slice: ""),
    // Folded
    Failure(ch: "σ", matching: .folded, input: "ς", reason: .nomatch, slice: ""),
    Failure(ch: "ß", matching: .folded, input: "ẞ", reason: .nomatch, slice: ""),
    // End of input
    Failure(ch: "a", matching: .exact, input: "", reason: .eof, slice: ""),
    Failure(ch: "a", matching: .simple, input: "", reason: .eof, slice: ""),
    Failure(ch: "a", matching: .folded, input: "", reason: .eof, slice: ""),
  ])
  func notFails(_ f: Failure) {
    let error = #expect(throws: ParseError<String>.self) {
      try char(not: f.ch, matching: f.matching).parse(f.input)
    }
    #expect(error?.reason == f.reason)
    #expect(error.map { String($0.slice) } == f.slice)
    #expect(error?.message == "Expected any character except \"\(f.ch)\".")
  }

  @Test func notInfersStringInputWithoutContext() {
    let notQuote = char(not: "'")
    #expect(type(of: notQuote) == Parser<String, Character>.self)
  }

  @Test func notCharacterArrayInput() throws {
    let input: [Character] = ["b", "a"]
    let result = try char(not: "a").parse(input)
    #expect(result.output == "b")
    #expect(Array(result.input) == ["a"])
  }

  @Test func notStopsManyAtExcludedCharacter() throws {
    let result = try char(not: "'")*.parse("ab'c")
    #expect(result.output == ["a", "b"])
    #expect(result.input == "'c")
  }

  // MARK: - char(_:) and char(not:) with a key path

  @Test func keyPathMatches() throws {
    let letter = try char(\.isLetter).parse("é1")
    #expect(letter.output == "é")
    #expect(letter.input == "1")
    let digit = try char(\.isNumber).parse("7a")
    #expect(digit.output == "7")
    #expect(digit.input == "a")
    let space = try char(\.isWhitespace).parse("\t!")
    #expect(space.output == "\t")
    #expect(space.input == "!")
  }

  @Test func keyPathFails() {
    let error = #expect(throws: ParseError<String>.self) {
      try char(\.isLetter).parse("1a")
    }
    #expect(error?.reason == .nomatch)
    #expect(error.map { String($0.slice) } == "")
    #expect(error?.message == nil)
  }

  @Test func keyPathFailsAtEnd() {
    let error = #expect(throws: ParseError<String>.self) {
      try char(\.isLetter).parse("")
    }
    #expect(error?.reason == .eof)
  }

  @Test func keyPathExpecting() {
    let error = #expect(throws: ParseError<String>.self) {
      try char(\.isLetter).expecting("Expected a letter.").parse("1")
    }
    #expect(error?.message == "Expected a letter.")
  }

  @Test func notKeyPathMatches() throws {
    let result = try char(not: \.isWhitespace).parse("a b")
    #expect(result.output == "a")
    #expect(result.input == " b")
  }

  @Test func notKeyPathFails() {
    let error = #expect(throws: ParseError<String>.self) {
      try char(not: \.isWhitespace).parse(" a")
    }
    #expect(error?.reason == .nomatch)
    #expect(error.map { String($0.slice) } == "")
  }

  @Test func notKeyPathFailsAtEnd() {
    let error = #expect(throws: ParseError<String>.self) {
      try char(not: \.isWhitespace).parse("")
    }
    #expect(error?.reason == .eof)
  }

  @Test func notKeyPathStopsMany() throws {
    let result = try char(not: \.isWhitespace)*.toString().parse("word rest")
    #expect(result.output == "word")
    #expect(result.input == " rest")
  }

  @Test func keyPathInfersStringInputWithoutContext() {
    let letter = char(\.isLetter)
    let nonSpace = char(not: \.isWhitespace)
    #expect(type(of: letter) == Parser<String, Character>.self)
    #expect(type(of: nonSpace) == Parser<String, Character>.self)
  }

  @Test func keyPathCharacterArrayInput() throws {
    let input: [Character] = ["x", "1"]
    let letter = try char(\.isLetter).parse(input)
    #expect(letter.output == "x")
    #expect(Array(letter.input) == ["1"])
    let nonLetter = try char(not: \.isLetter).parse(Array(letter.input))
    #expect(nonLetter.output == "1")
    #expect(nonLetter.input.isEmpty)
  }

  @Test func keyPathFromVariable() throws {
    let isNumber = \Character.isNumber
    #expect(try char(isNumber).parse("5").output == "5")
    #expect(try char(not: isNumber).parse("x").output == "x")
  }

  @Test func whitespacedRequiresWhitespace() {
    let error = #expect(throws: ParseError<String>.self) {
      try char("a").whitespaced1().parse("a")
    }
    #expect(error?.reason == .nomatch)
    #expect(error?.message == "Expected whitespace.")
  }

  @Test func consumesForNextParser() throws {
    let p: Parser<String, [Character]> = chain(char("a"), char("B", matching: .simple), char("c"))
    let result = try p.parse("abc!")
    #expect(result.output == ["a", "b", "c"])
    #expect(result.input == "!")
  }
}
