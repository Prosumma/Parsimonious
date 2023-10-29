//
//  Combinators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-20.
//

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

public func debug<C: Collection, T>(_ parser: @escaping @autoclosure () -> Parser<C, T>, tag: String, log: @escaping (String) -> Void) -> Parser<C, T> {
  .init { source, index in
    let i = source.distance(from: source.startIndex, to: index)
    log("About to execute parser \(tag) at index distance \(i) from start.")
    switch parser()(source, at: index) {
    case let .success(state):
      let d = source.distance(from: index, to: state.range.upperBound)
      log("Parser \(tag) suceeded, consuming \(d) indices, with output \(state.output).")
      return .success(state)
    case let .failure(failure):
      log("Parser \(tag) failed with error \(failure).")
      return .failure(failure)
    }
  }
}

public func debug<C: Collection, T>(_ parser: @escaping @autoclosure () -> Parser<C, T>, tag: String) -> Parser<C, T> {
  debug(parser(), tag: tag, log: { print($0) })
}
