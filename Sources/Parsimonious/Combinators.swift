//
//  Combinators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-20.
//

/// Monadic composition
public func >>= <C: Collection, Output, NewOutput>(
  lhs: @escaping @autoclosure () -> Parser<C, Output>,
  rhs: @escaping (Output) -> Parser<C, NewOutput>
) -> Parser<C, NewOutput> {
  lhs().flatMap(rhs)
}

/**
 Monadic composition, ignoring the previous argument.
 
 Same as Haskell's `>>`, but less general.
 */
public func *>= <C: Collection, Output, NewOutput>(
  lhs: @escaping @autoclosure () -> Parser<C, Output>,
  rhs: @escaping @autoclosure () -> Parser<C, NewOutput>
) -> Parser<C, NewOutput> {
  lhs().flatMap { _ in rhs() }
}

/**
 Operator version of `map`.
 
 Equivalent of Haskell's `<&>`, but less general.
 */
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
      let range = index..<source.index(after: index)
      result = .success(.init(output: element, range: range))
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
    var result: ParseResult<C, [T]> = .success(.init(output: [], range: index..<index))
    LOOP: while outputs.count < to {
      switch parser(source, at: index) {
      case let .success(state):
        index = state.range.upperBound
        outputs.append(state.output)
        result = .success(.init(output: outputs, range: state.range))
      case let .failure(error):
        if outputs.count < from {
          result = .failure(error)
        }
        break LOOP
      }
    }
    return result
  }.ranged()
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
  _ model: @escaping @autoclosure () -> C.Element
) -> Parser<C, C.Element> where C.Element: Equatable {
  match(^model())
}

public func match<C: Collection>(
  _ model: @escaping @autoclosure () -> C.Element,
  from: Int,
  to: Int
) -> Parser<C, [C.Element]> where C.Element: Equatable {
  match(^model(), from: from, to: to)
}

public func match<C: Collection>(
  _ range: Range<Int>,
  _ model: @escaping @autoclosure () -> C.Element
) -> Parser<C, [C.Element]> where C.Element: Equatable {
  match(range, ^model())
}

public func match<C: Collection>(
  _ exactly: Int,
  _ model: @escaping @autoclosure () -> C.Element
) -> Parser<C, [C.Element]> where C.Element: Equatable {
  match(exactly, ^model())
}

public func <|> <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, T>,
  rhs: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  match(any: lhs(), rhs())
}

public func `optional`<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>,
  default defaultValue: @escaping @autoclosure () -> T
) -> Parser<C, T> {
  parser() <|> just(defaultValue())
}

public func `optional`<C: Collection, T: Defaultable>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  optional(parser(), default: .defaultValue)
}

public prefix func * <C: Collection, T: Defaultable>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  optional(parser())
}

/**
 Aggregates the result of all the parsers into an array.
 
 Most of the time, it's more convenient to use the more polymorphic
 `+` operator.
 
 - Note: This is Haskell's `sequence`, but less general, and with
 a Swiftier name.
 */
public func chain<C: Collection, T>(
  _ parsers: @escaping @autoclosure () -> [Parser<C, T>]
) -> Parser<C, [T]> {
  .init { source, index in
    var outputs: [T] = []
    var index = index
    var result: ParseResult<C, [T]> = .success(.init(output: outputs, range: index..<index))
    PARSE: for parser in parsers() {
      switch parser(source, at: index) {
      case .success(let state):
        outputs.append(state.output)
        result = .success(.init(output: outputs, range: index..<state.range.upperBound))
        index = state.range.upperBound
      case .failure(let error):
        result = .failure(error)
        break PARSE
      }
    }
    return result
  }.ranged()
}

/**
 Aggregates the result of all the parsers into an array.
 
 - Note: This is Haskell's `sequence`, but less general, and with
 a Swiftier name.
 */
func chain<C: Collection, T>(
  _ parsers: Parser<C, T>...
) -> Parser<C, [T]> {
  chain(parsers)
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, [T]>,
  rhs: @escaping @autoclosure () -> Parser<C, [T]>
) -> Parser<C, [T]> {
  chain(lhs(), rhs()) >>> { Array($0.joined()) }
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, T>,
  rhs: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  chain(lhs(), rhs())
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, T>,
  rhs: @escaping @autoclosure () -> Parser<C, [T]>
) -> Parser<C, [T]> {
  lhs().list() + rhs()
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, [T]>,
  rhs: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  lhs() + rhs().list()
}

public func *> <C: Collection, L, R>(
  lhs: @escaping @autoclosure () -> Parser<C, L>,
  rhs: @escaping @autoclosure () -> Parser<C, R>
) -> Parser<C, R> {
  lhs().flatMap { _ in rhs() }
}

public func <* <C: Collection, L, R>(
  lhs: @escaping @autoclosure () -> Parser<C, L>,
  rhs: @escaping @autoclosure () -> Parser<C, R>
) -> Parser<C, L> {
  lhs().flatMap { output in
    rhs() *>> output
  }
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

/**
 Consumes the underlying match, but discards it
 in favor of the default value.
 
 Why does it use two different types? Because it
 allows `skip` to be used in more environments.
 For example:
 
 ```swift
 chain(many1S(char(any: "abc")), skip(eof())).joined()
 ```
 
 `eof()` returns `Void`, but embedding it in `skip`,
 the types work out.
 
 It's often easier, however, to use `<*` or `*>`, e.g.,
 
 ```swift
 many1S(char(any: "abc")) <* eof()
 ```
 */
public func skip<C: Collection, T, S: Defaultable>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, S> {
  parser() *>> S.defaultValue
}

public func peek<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, Void> {
  .init { source, index in
    parser()(source, at: index).flatMap { _ in
      .success(.init(output: (), range: index..<index))
    }
  }
}

public func delimit<C, T, B, E>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>,
  by begin: @escaping @autoclosure () -> Parser<C, B>,
  and end: @escaping @autoclosure () -> Parser<C, E>
) -> Parser<C, T> {
  begin() *> parser() <* end()
}

public func delimit<C, T, D>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>,
  by delimiter: @escaping @autoclosure () -> Parser<C, D>
) -> Parser<C, T> {
  delimit(parser(), by: delimiter(), and: delimiter())
}

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

public func eof<C: Collection>() -> Parser<C, Void> {
  .init { source, index in
    if index == source.endIndex {
      return .success(.init(output: (), range: index..<index))
    } else {
      return .failure(.init(reason: .nomatch, index: index))
    }
  }
}

/**
 This parser fails if the passed-in parser succeeds.
 
 In either case, it does not consume anything. Chiefly
 useful for look-ahead. It's essentialy the logical
 inverse of `peek`:
 
 ```swift
 string("foo") <* not(",")
 ```

 The expression above matches the string "foo", but only
 if it's not followed by a comma.
 */
public func not<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, Void> {
  .init { source, index in
    switch parser()(source, at: index) {
    case .success:
      return .failure(.init(reason: .nomatch, index: index))
    case .failure:
      return .success(.init(output: (), range: index..<index))
    }
  }
}

public func not<C: Collection, T>(
  any parsers: @escaping @autoclosure () -> [Parser<C, T>]
) -> Parser<C, Void> {
  not(match(any: parsers()))
}

public func not<C: Collection, T>(
  any parsers: Parser<C, T>...
) -> Parser<C, Void> {
  not(any: parsers)
}

/**
 This is chiefly useful for extracting a value from an enum case, e.g.,
 
 ```swift
 extract {
   guard case .foo(let s) = $0 else { return nil }
   return s
 }
 ```
 */
public func extract<C: Collection, T>(_ get: @escaping (C.Element) -> T?) -> Parser<C, T> {
  match() >>> {
    guard let value = get($0) else {
      throw ParseError<C>.Reason.nomatch
    }
    return value
  }
}
