//
//  Parsing.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

public protocol Parsing<Input, Output>: Sendable {
  associatedtype Input: Collection & Sendable where Input.SubSequence: Sendable
  associatedtype Output

  func parse(_ input: Input.SubSequence) throws(ParseError<Input>) -> ParseOutput<Input, Output>
  func eraseToParser() -> Parser<Input, Output>
}

extension Parsing {
  public func eraseToParser() -> Parser<Input, Output> {
    return .init(parser: self)
  }

  /// Parses from the start of `input`. Doesn't require the parser to consume all of it:
  /// the rest is returned in the output. Use `end()` to require the end of the input.
  public func parse(_ input: Input) throws(ParseError<Input>) -> ParseOutput<Input, Output> {
    try parse(input[...])
  }

  public func flatMap<NewOutput>(
    _ makeNextParser: @Sendable @escaping (Output) -> some Parsing<Input, NewOutput>
  ) -> Parser<Input, NewOutput> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let output = try parser.parse(input)
      let nextParser = makeNextParser(output.output)
      return try nextParser.parse(output.input)
    }
  }

  public func flatMap<NewOutput>(
    _ parse:
      @Sendable @escaping (ParseOutput<Input, Output>) throws(ParseError<Input>) -> ParseOutput<
        Input, NewOutput
      >
  ) -> Parser<Input, NewOutput> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let output = try parser.parse(input)
      return try parse(output)
    }
  }
}

/// Parses `input` with `parser` and returns its output.
///
/// Doesn't require `parser` to consume all of `input`: `parse("ab", with: char("a"))` returns `"a"`
/// and ignores the `"b"`. Use `parser.end()` to require the end of the input.
///
/// This is the entry point for running a parser. Don't use it inside other parsing machinery:
/// it returns only the output, not the remaining input, so nothing can continue from where it
/// stopped. Call the parser's own `parse(_:)` there instead.
public func parse<Input: Collection & Sendable, Output>(
  _ input: Input,
  with parser: some Parsing<Input, Output>
) throws(ParseError<Input>) -> Output {
  try parser.parse(input).output
}
