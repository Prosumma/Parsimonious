//
//  Location.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-25.
//

/// The 1-based line and column of `index` in `input`.
///
/// Use this to report a position you recorded while parsing, such as the start of a slice
/// from `captured()`, when the problem is found later: an undefined name, say, or a
/// duplicate definition. `ParseError.location(in:)` is the same thing for a parse error.
///
/// Columns count characters, and every newline character starts a new line. That includes
/// `"\r\n"`, which Swift treats as a single character.
public func location<Input: Collection>(
  of index: Input.Index,
  in input: Input
) -> (line: Int, column: Int) where Input.Element == Character {
  var line = 1
  var column = 1
  for ch in input[..<index] {
    if ch.isNewline {
      line += 1
      column = 1
    } else {
      column += 1
    }
  }
  return (line, column)
}
