//
//  Tuple.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-25.
//

private func tupleHelper<C: Collection, A: Sendable>(
  _ parser: Parser<C, A>,
  _ source: C,
  _ range: inout Range<C.Index>
) throws -> A where C.Index: Sendable, C.Element: Sendable {
  switch parser(source, at: range.upperBound) {
  case .success(let state):
    range = state.range
    return state.output
  case .failure(let error):
    range = error.index..<error.index
    throw error
  }
}

public func tuple<C: Collection, each A: Sendable>(_ parser: repeat Parser<C, each A>) -> Parser<C, (repeat each A)>
  where C.Index: Sendable, C.Element: Sendable
{
  // This hack is required due to a bug in Swift 6
  let parsers = (repeat each parser)
  return .init { source, index in
    var range: Range<C.Index> = index..<index
    do {
      // Side effects for the win!
      let result = try (repeat tupleHelper(each parsers, source, &range))
      return .success(.init(output: result, range: index..<range.upperBound))
    } catch let error as ParseError<C> {
      return .failure(error)
    } catch {
      // This is dead code, here strictly for the compiler. No way to hit
      // it or test it ever.
      return .failure(.init(reason: .error(error), index: range.lowerBound))
    }
  }
}