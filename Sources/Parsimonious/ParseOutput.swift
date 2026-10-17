//
//  ParseOutput.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

public struct ParseOutput<Input: Collection, Output> {
  public let input: Input.SubSequence
  public let output: Output

  public init(input: Input.SubSequence, output: Output) {
    self.input = input
    self.output = output
  }

  public func map<NextOutput>(_ transform: (Output) throws -> NextOutput) rethrows -> ParseOutput<Input, NextOutput> {
    try .init(input: input, output: transform(output))
  }
}

extension ParseOutput: Sendable where Input.SubSequence: Sendable, Output: Sendable {}
extension ParseOutput: Equatable where Input.SubSequence: Equatable, Output: Equatable {}
