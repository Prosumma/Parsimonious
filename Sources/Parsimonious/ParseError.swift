//
//  ParseError.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

public struct ParseError<Input: Collection>: Error {
  public enum Reason: Sendable, Equatable {
    case nomatch, eof
  }

  public let reason: Reason
  /// The input the failing parser consumed before it failed: `startIndex` is where it
  /// started, and `endIndex` is how far it got. Empty if it failed on its first element.
  public let slice: Input.SubSequence
  /// Whether the error is committed: `or` and repetitions rethrow it instead of backtracking.
  public var committed: Bool
  public var message: String?
  public let error: any Error?

  public init(
    reason: Reason,
    slice: Input.SubSequence,
    committed: Bool = false,
    message: String? = nil,
    error: any Error? = nil,
  ) {
    self.reason = reason
    self.slice = slice
    self.committed = committed
    self.message = message
    self.error = error
  }

  /// Whether the parser that received `input` consumed some of it before failing.
  public func consumed(relativeTo input: Input.SubSequence) -> Bool {
    input.startIndex < slice.endIndex
  }
}

extension ParseError: Sendable where Input.SubSequence: Sendable {}

public extension ParseError where Input.Element == Character {
  /// The 1-based line and column in `input` where the failing parser stopped, which is
  /// `slice.endIndex`.
  ///
  /// `input` must be the collection that was parsed, since the error's indices refer to it.
  /// Columns count characters, and every newline character starts a new line. That includes
  /// `"\r\n"`, which Swift treats as a single character.
  func location(in input: Input) -> (line: Int, column: Int) {
    var line = 1
    var column = 1
    for ch in input[..<slice.endIndex] {
      if ch.isNewline {
        line += 1
        column = 1
      } else {
        column += 1
      }
    }
    return (line, column)
  }
}
