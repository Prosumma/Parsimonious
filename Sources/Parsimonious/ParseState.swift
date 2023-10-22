//
//  ParseState.swift
//  Parsimonious
//
//  Created by Gregor Higley on 2023-10-19.
//

/**
 The output state of a successful parse.
 
 A valid `ParseState` contains the `output` of the parse
 as well as the `range` consumed in the underlying
 collection.
 */
public struct ParseState<Source: Collection, Output> {
  public let output: Output
  public let range: Range<Source.Index>

  public init(output: Output, range: Range<Source.Index>) {
    self.output = output
    self.range = range
  }

  public func map<NewOutput>(
    _ transform: (Output) throws -> NewOutput
  ) rethrows -> ParseState<Source, NewOutput> {
    try .init(output: transform(output), range: range)
  }
  
  public func mapWithRange<NewOutput>(
    _ transform: (Output, Range<Source.Index>) throws -> (NewOutput, Range<Source.Index>)
  ) rethrows -> ParseState<Source, NewOutput> {
    let (NewOutput, targetRange) = try transform(output, range)
    return .init(output: NewOutput, range: targetRange)
  }
  
  public func flatMap<NewOutput>(
    _ transform: (Output, Range<Source.Index>) throws -> ParseState<Source, NewOutput>
  ) rethrows -> ParseState<Source, NewOutput> {
    try transform(output, range)
  }
}
