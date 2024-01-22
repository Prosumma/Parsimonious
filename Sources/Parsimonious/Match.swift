//
//  Match.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-25.
//

/**
 Matches any single element of the underlying `Collection`.
 Does not match EOF.
 */
public func match<C: Collection>() -> Parser<C, C.Element> {
  match { _ in true }
}

public func match<C: Collection, T>(any parsers: @escaping @autoclosure () -> [Parser<C, T>]) -> Parser<C, T> {
  .init { source, index in
    var lastError = ParseError<C>(reason: .nomatch, index: index)
    PARSE: for parser in parsers() {
      switch parser(source, at: index) {
      case let .success(state):
        return .success(state)
      case let .failure(error):
        lastError = error
        continue PARSE
      }
    }
    return .failure(lastError)
  }
}

public func match<C: Collection, T>(any parsers: Parser<C, T>...) -> Parser<C, T> {
  match(any: parsers)
}

public func match<C: Collection>(_ predicate: @escaping ElementPredicate<C.Element>) -> Parser<C, C.Element> {
  .init { source, index in
    guard index < source.endIndex else { return .failure(.init(reason: .eof, index: index)) }
    let element = source[index]
    let result: ParseResult<C, C.Element>
    if predicate(element) {
      result = .success(.init(output: element, index: source.index(after: index)))
    } else {
      result = .failure(.init(reason: .nomatch, index: index))
    }
    return result
  }
}

public func match<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>,
  from: Int,
  to: Int
) -> Parser<C, [T]> {
  .init { source, index in
    guard to - from >= 0 else { return .failure(.init(reason: .outOfBounds, index: index)) }
    let parser = parser()
    var index = index
    var outputs: [T] = []
    var result: ParseResult<C, [T]> = .success(.init(output: [], index: index))
    LOOP: while outputs.count < to {
      switch parser(source, at: index) {
      case let .success(state):
        index = state.index
        outputs.append(state.output)
        result = .success(.init(output: outputs, index: index))
      case let .failure(error):
        if outputs.count < from {
          result = .failure(error)
        }
        break LOOP
      }
    }
    return result
  }
}

public func match<C: Collection, T>(
  _ range: Range<Int>,
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  match(parser(), from: range.lowerBound, to: range.upperBound)
}

public func match<C: Collection, T>(
  _ exactly: Int,
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  match(parser(), from: exactly, to: exactly)
}

public func match<C: Collection>(
  _ predicate: @escaping ElementPredicate<C.Element>,
  from: Int,
  to: Int
) -> Parser<C, [C.Element]> {
  match(match(predicate), from: from, to: to)
}

public func match<C: Collection>(
  _ range: Range<Int>,
  _ predicate: @escaping ElementPredicate<C.Element>
) -> Parser<C, [C.Element]> {
  match(range, match(predicate))
}

public func match<C: Collection>(
  _ exactly: Int,
  _ predicate: @escaping ElementPredicate<C.Element>
) -> Parser<C, [C.Element]> {
  match(exactly, match(predicate))
}

public func match<C: Collection>(
  _ model: C.Element
) -> Parser<C, C.Element> where C.Element: Equatable {
  match(^model)
}

public func match<C: Collection>(
  _ model: C.Element,
  from: Int,
  to: Int
) -> Parser<C, [C.Element]> where C.Element: Equatable {
  match(^model, from: from, to: to)
}

public func match<C: Collection>(
  _ range: Range<Int>,
  _ model: C.Element
) -> Parser<C, [C.Element]> where C.Element: Equatable {
  match(range, ^model)
}

public func match<C: Collection>(
  _ exactly: Int,
  _ model: @escaping @autoclosure () -> C.Element
) -> Parser<C, [C.Element]> where C.Element: Equatable {
  match(exactly, ^model())
}

public func many<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  match(0..<Int.max, parser())
}

public func many<C: Collection, T, S>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>,
  separator: @escaping @autoclosure () -> Parser<C, S>
) -> Parser<C, [T]> {
  optional(parser().list()) + many(separator() *> parser())
}

public postfix func * <C: Collection, T>(
  parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  many(parser())
}

public func many1<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  let parser = parser()
  return parser + many(parser)
}

public postfix func + <C: Collection, T>(
  parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  many1(parser())
}

public func many1<C: Collection, T, S>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>,
  separator: @escaping @autoclosure () -> Parser<C, S>
) -> Parser<C, [T]> {
  parser() + many(separator() *> parser())
}

public func <|> <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, T>,
  rhs: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  match(any: lhs(), rhs())
}
