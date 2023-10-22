//
//  File.swift
//  
//
//  Created by Greg Higley on 2023-10-19.
//

public typealias Parse<Source: Collection, Output> = (Source, Source.Index) -> ParseResult<Source, Output>
public typealias ParseResult<Source: Collection, Output> = Result<ParseState<Source, Output>, ParseError<Source>>

public struct Parser<Source: Collection, Output> {
  private let parse: Parse<Source, Output>

  public init(parse: @escaping Parse<Source, Output>) {
    self.parse = parse
  }

  public init(value: Output) {
    self.init { _, index in
      // In other words, outputs the value but consumes
      // none of the underlying collection.
      .success(.init(output: value, range: index..<index))
    }
  }

  public func callAsFunction(_ source: Source, at index: Source.Index) -> ParseResult<Source, Output> {
    parse(source, index)
  }

  public func callAsFunction(_ source: Source) -> ParseResult<Source, Output> {
    parse(source, source.startIndex)
  }
}

/**
 This is Haskell's `join` with a Swiftier name.
 
 It helps to make `flatMap` (i.e., `bind`, `>>=`) easier to write.
 */
public func flatten<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, Parser<C, T>>
) -> Parser<C, T> {
  .init { source, index in
    parser()(source, at: index).flatMap { $0.output(source, at: $0.range.upperBound) }
  }
}

public extension Parser {
  func ranged() -> Parser<Source, Output> {
    .init { source, index in
      self(source, at: index).flatMap {
        .success(.init(output: $0.output, range: index..<$0.range.upperBound))
      }
    }
  }
  
  func map<NewOutput>(
    _ transform: @escaping (Output) throws -> NewOutput
  ) -> Parser<Source, NewOutput> {
    .init { source, index in
      self(source, at: index).flatMap { state in
        throwToResult(index) {
          try state.map(transform)
        }
      }
    }
  }

  func flatMap<NewOutput>(
    _ transform: @escaping (Output) -> Parser<Source, NewOutput>
  ) -> Parser<Source, NewOutput> {
    flatten(map(transform)).ranged()
  }

  func list() -> Parser<Source, [Output]> {
    map { [$0] }
  }
  
  func withRange() -> Parser<Source, (Range<Source.Index>, Output)> {
    .init { source, index in
      self(source, at: index).map { state in
        state.mapWithRange { output, range in
          ((range, output), range)
        }
      }
    }
  }
}

public func parse<C: Collection, T>(_ collection: C, with parser: Parser<C, T>) throws -> T {
  try parser(collection).get().output
}
