//
//  Parser.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-19.
//

public typealias Parse<Source: Collection, Output> = (Source, Source.Index) -> ParseResult<Source, Output>

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

public func flatten<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, Parser<C, T>>
) -> Parser<C, T> {
  .init { source, index in
    parser()(source, at: index) >>= { $0.output(source, at: $0.range.upperBound) }
  }
}

public func zip<C: Collection, L, R, T>(
  _ lhs: @escaping @autoclosure () -> Parser<C, L>,
  _ rhs: @escaping @autoclosure () -> Parser<C, R>,
  _ combine: @escaping (L, R) throws -> T
) -> Parser<C, T> {
  lhs().flatMap { lvalue in
    rhs().map { rvalue in try combine(lvalue, rvalue) }
  }.ranged()
}

public func reduce<C: Collection, T, R>(
  _ initial: R,
  _ parsers: @escaping @autoclosure () -> [Parser<C, T>],
  _ combine: @escaping (R, T) throws -> R
) -> Parser<C, R> {
  .init { source, index in
    var initial = initial
    var index = index
    for parser in parsers() {
      switch parser(source, at: index) {
      case let .success(state):
        do {
          initial = try combine(initial, state.output)
          index = state.range.upperBound
        } catch {
          return .failure(.init(reason: .error(error), index: index))
        }
      case let .failure(error):
        return .failure(error)
      }
    }
    return .success(.init(output: initial, range: index..<index))
  }.ranged()
}

public func reduce<C: Collection, T, R>(
  _ initial: R,
  _ parsers: Parser<C, T>...,
  combine: @escaping (R, T) throws -> R
) -> Parser<C, R> {
  reduce(initial, parsers, combine)
}

public extension Parser {
  func ranged() -> Parser<Source, Output> {
    .init { source, index in
      self(source, at: index) >>= {
        .success(.init(output: $0.output, range: index..<$0.range.upperBound))
      }
    }
  }

  func map<NewOutput>(
    _ transform: @escaping (Output) throws -> NewOutput
  ) -> Parser<Source, NewOutput> {
    .init { source, index in
      self(source, at: index) >>= { state in
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
      self(source, at: index) >>> { state in
        state.mapWithRange { output, range in
          ((range, output), range)
        }
      }
    }
  }
}

/// Monadic composition
public func >>= <C: Collection, Output, NewOutput>(
  lhs: @escaping @autoclosure () -> Parser<C, Output>,
  rhs: @escaping (Output) -> Parser<C, NewOutput>
) -> Parser<C, NewOutput> {
  lhs().flatMap(rhs)
}

public func *> <C: Collection, L, R>(
  lhs: @escaping @autoclosure () -> Parser<C, L>,
  rhs: @escaping @autoclosure () -> Parser<C, R>
) -> Parser<C, R> {
  zip(lhs(), rhs()) { l, r in r }
}

public func <* <C: Collection, L, R>(
  lhs: @escaping @autoclosure () -> Parser<C, L>,
  rhs: @escaping @autoclosure () -> Parser<C, R>
) -> Parser<C, L> {
  zip(lhs(), rhs()) { l, r in l }
}

public func >>> <C: Collection, Input, Output>(
  lhs: @escaping @autoclosure () -> Parser<C, Input>,
  rhs: @escaping (Input) throws -> Output
) -> Parser<C, Output> {
  lhs().map(rhs)
}

public func *>> <C: Collection, Input, Output>(
  lhs: @escaping @autoclosure () -> Parser<C, Input>,
  rhs: @escaping @autoclosure () -> Output
) -> Parser<C, Output> {
  lhs().map { _ in rhs() }
}

public func just<C: Collection, T>(
  _ value: @escaping @autoclosure () -> T
) -> Parser<C, T> {
  .init(value: value())
}

public func fail<C: Collection, T>(
  _ reason: ParseError<C>.Reason
) -> Parser<C, T> {
  .init { _, index in
    .failure(.init(reason: reason, index: index))
  }
}

public func fail<C: Collection, T>(
  _ error: any Error
) -> Parser<C, T> {
  fail(.error(error))
}

public func deferred<C: Collection, T>(_ parse: @escaping Parse<C, T>) -> Parser<C, T> {
  .init(parse: parse)
}

public func deferred<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  parser()
}

public func parse<C: Collection, T>(_ collection: C, with parser: Parser<C, T>) throws -> T {
  try parser(collection).get().output
}
