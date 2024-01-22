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
  public let index: Source.Index

  public init(output: Output, index: Source.Index) {
    self.output = output
    self.index = index
  }

  public func map<NewOutput>(
    _ transform: (Output) throws -> NewOutput
  ) rethrows -> ParseState<Source, NewOutput> {
    try .init(output: transform(output), index: index)
  }

  public func mapWithIndex<NewOutput>(
    _ transform: (Output, Source.Index) throws -> (NewOutput, Source.Index)
  ) rethrows -> ParseState<Source, NewOutput> {
    let (newOutput, targetIndex) = try transform(output, index)
    return .init(output: newOutput, index: targetIndex)
  }

  public func flatMap<NewOutput>(
    _ transform: (Output, Source.Index) throws -> ParseState<Source, NewOutput>
  ) rethrows -> ParseState<Source, NewOutput> {
    try transform(output, index)
  }
}

public func >>> <Source: Collection, Output, NewOutput>(
  state: ParseState<Source, Output>,
  transform: (Output) throws -> NewOutput
) rethrows -> ParseState<Source, NewOutput> {
  try state.map(transform)
}

public func *>> <Source: Collection, Output, NewOutput>(
  state: ParseState<Source, Output>,
  newOutput: @escaping @autoclosure () -> NewOutput
) -> ParseState<Source, NewOutput> {
  state.map { _ in newOutput() }
}

public func >>= <Source: Collection, Output, NewOutput>(
  state: ParseState<Source, Output>,
  transform: (Output, Source.Index) throws -> ParseState<Source, NewOutput>
) rethrows -> ParseState<Source, NewOutput> {
  try state.flatMap(transform)
}
