//
//  Parser.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

public struct Parser<Input: Collection, Output> where Input: Sendable, Input.SubSequence: Sendable {
  private let _parse:
    @Sendable (Input.SubSequence) throws(ParseError<Input>) -> ParseOutput<Input, Output>

  public init(
    parse:
      @Sendable @escaping (Input.SubSequence) throws(ParseError<Input>) -> ParseOutput<
        Input, Output
      >
  ) {
    self._parse = parse
  }

  public init(parser: some Parsing<Input, Output>) {
    self.init { (input) throws(ParseError<Input>) in
      try parser.parse(input)
    }
  }
}

extension Parser: Parsing<Input, Output> {
  public func parse(_ input: Input.SubSequence) throws(ParseError<Input>) -> ParseOutput<
    Input, Output
  > {
    try _parse(input)
  }
  public func eraseToParser() -> Parser<Input, Output> {
    self
  }
}
