//
//  Tuple.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-25.
//

#if swift(>=5.9)

private func tupleHelper<C: Collection, A>(
  _ parser: Parser<C, A>,
  _ source: C,
  _ range: inout Range<C.Index>
) throws -> A {
  switch parser(source, at: range.upperBound) {
  case .success(let state):
    range = state.range
    return state.output
  case .failure(let error):
    range = error.index..<error.index
    throw error
  }
}

public func tuple<C: Collection, each A>(_ parser: repeat Parser<C, each A>) -> Parser<C, (repeat each A)> {
  .init { source, index in
    var range: Range<C.Index> = index..<index
    do {
      // Side effects for the win!
      let result = try (repeat tupleHelper(each parser, source, &range))
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

#else

public func tuple<C: Collection, A, B>(
  _ parserA: @escaping @autoclosure () -> Parser<C, A>,
  _ parserB: @escaping @autoclosure () -> Parser<C, B>
) -> Parser<C, (A, B)> {
  parserA() >>= { a in
    parserB() >>> { b in (a, b) }
  }
}

public func tuple<C: Collection, A, B, D>(
  _ parserA: @escaping @autoclosure () -> Parser<C, A>,
  _ parserB: @escaping @autoclosure () -> Parser<C, B>,
  _ parserD: @escaping @autoclosure () -> Parser<C, D>
) -> Parser<C, (A, B, D)> {
  parserA() >>= { a in
    parserB() >>= { b in
      parserD() >>> { d in (a, b, d) }
    }
  }
}

#endif
