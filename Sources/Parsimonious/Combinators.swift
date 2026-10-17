//
//  Combinators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

public extension Parsing {
  func map<NextOutput>(_ transform: @Sendable @escaping (Output) throws -> NextOutput) -> Parser<Input, NextOutput> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let output = try parser.parse(input)
      do {
        return try output.map(transform)
      } catch {
        throw ParseError(reason: .nomatch, slice: input[input.startIndex..<output.input.startIndex], error: error)
      }
    }
  }

  func map<NextOutput>(_ transform: @Sendable @escaping () throws -> NextOutput) -> Parser<Input, NextOutput> {
    map { _ in try transform() }
  }

  func array() -> Parser<Input, [Output]> {
    map { [$0] }
  }

  func many() -> Parser<Input, [Output]> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      var outputs: [Output] = []
      var nextInput: Input.SubSequence = input
      while true {
        do throws(ParseError<Input>) {
          let output = try parser.parse(nextInput)
          if output.input.startIndex == nextInput.startIndex {
            // We returned a value but consumed no input.
            // If we don't break, we'll loop forever.
            break
          }
          outputs.append(output.output)
          nextInput = output.input
        } catch {
          if error.committed {
            throw error
          }
          break
        }
      }
      return .init(input: nextInput, output: outputs)
    }
  }

  func many1() -> Parser<Input, [Output]> {
    join(array(), many())
  }

  func many<SepOutput>(separatedBy sep: some Parsing<Input, SepOutput>) -> Parser<Input, [Output]> {
    many1(separatedBy: sep) <|> just([])
  }

  func many1<SepOutput>(separatedBy sep: some Parsing<Input, SepOutput>) -> Parser<Input, [Output]> {
    join(array(), (sep *> self)*)
  }

  /// Matches exactly `limit` repetitions, failing with the first one that fails.
  ///
  /// Unlike `many()`, this doesn't stop when a repetition consumes nothing: the loop is
  /// bounded by `limit`, so `just("z").count(3)` outputs `["z", "z", "z"]`.
  func count(_ limit: Int) -> Parser<Input, [Output]> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      var outputs: [Output] = []
      var rest = input
      while outputs.count < limit {
        let output = try parser.parse(rest)
        outputs.append(output.output)
        rest = output.input
      }
      return .init(input: rest, output: outputs)
    }
  }

  /// Matches up to `limit` repetitions, stopping early as `many()` does: at the first
  /// failure that isn't committed, or when a repetition consumes nothing.
  func count(upTo limit: Int) -> Parser<Input, [Output]> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      var outputs: [Output] = []
      var rest = input
      while outputs.count < limit {
        do throws(ParseError<Input>) {
          let output = try parser.parse(rest)
          if output.input.startIndex == rest.startIndex {
            // We returned a value but consumed no input.
            // If we don't stop, we'll loop forever.
            break
          }
          outputs.append(output.output)
          rest = output.input
        } catch {
          if error.committed {
            throw error
          }
          break
        }
      }
      return .init(input: rest, output: outputs)
    }
  }

  ///  Most of the time when you have an optional, you're joining it to something else,
  ///  so the pattern here is something like:
  ///
  ///  ```swift
  ///   join(char(anyOf: "+-").optional(), integer).toString().map(toInteger)
  ///  ```
  func optional() -> Parser<Input, [Output]> {
    array() <|> just([])
  }

  /// Outputs what `self` would output, without consuming anything. If `self` fails,
  /// `peek()` fails with the same error.
  ///
  /// Useful for choosing what to parse next, as in
  /// `char(anyOf: "{[").peek().flatMap { $0 == "{" ? object : array }`.
  func peek() -> Parser<Input, Output> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let output = try parser.parse(input)
      return .init(input: input, output: output.output)
    }
  }

  /// Succeeds without consuming anything where `self` fails, and fails where `self` succeeds,
  /// as in `string("if") <* char(\.isLetter).not()`, which matches `if` but not the start of `iffy`.
  ///
  /// A committed error from `self` is rethrown rather than treated as "not matched". Committed
  /// means the input can't be anything else: `object.not()` on a malformed object reports the
  /// malformed object instead of succeeding. To treat any failure as "not matched", write
  /// `self.uncommit().not()`.
  ///
  /// When `self` succeeds, the error has no message; add one with `expecting(_:)`.
  func not() -> Parser<Input, ()> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      do throws(ParseError<Input>) {
        _ = try parser.parse(input)
      } catch {
        if error.committed {
          throw error
        }
        return .init(input: input, output: ())
      }
      throw ParseError(reason: .nomatch, slice: input[..<input.startIndex])
    }
  }

  func followed<FollowingOutput>(by follower: some Parsing<Input, FollowingOutput>) -> Parser<Input, Output> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let output = try parser.parse(input)
      let followingOutput = try follower.parse(output.input)
      return .init(input: followingOutput.input, output: output.output)
    }
  }

  func preceded<PrecedingOutput>(by preceder: some Parsing<Input, PrecedingOutput>) -> Parser<Input, Output> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let precedingOutput = try preceder.parse(input)
      return try parser.parse(precedingOutput.input)
    }
  }

  func delimited<DelimiterOutput>(by delimiter: some Parsing<Input, DelimiterOutput>) -> Parser<Input, Output> {
    preceded(by: delimiter).followed(by: delimiter)
  }

  func delimited<FirstDelimiterOutput, SecondDelimiterOutput>(
    by firstDelimiter: some Parsing<Input, FirstDelimiterOutput>,
    and secondDelimiter: some Parsing<Input, SecondDelimiterOutput>,
  ) -> Parser<Input, Output> {
    firstDelimiter *> self <* secondDelimiter
  }

  /// Returns the output along with the subsequence that was parsed.
  func captured() -> Parser<Input, (Output, Input.SubSequence)> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      let output = try parser.parse(input)
      return .init(input: output.input, output: (output.output, input[..<output.input.startIndex]))
    }
  }
  
  func end() -> Parser<Input, Output> {
    followed(by: Parsers.end)
  }

  func uncommit() -> Parser<Input, Output> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      do throws(ParseError<Input>) {
        return try parser.parse(input)
      } catch {
        var error = error
        error.committed = false
        throw error
      }
    }
  }

  func mapError(_ transform: @Sendable @escaping (Input.SubSequence, inout ParseError<Input>) -> Void) -> Parser<Input, Output> {
    let parser = self
    return Parser { (input) throws(ParseError<Input>) in
      do throws(ParseError<Input>) {
        return try parser.parse(input)
      } catch {
        var error = error
        transform(input, &error)
        throw error
      }
    }
  }

  func mapError(_ transform: @Sendable @escaping (inout ParseError<Input>) -> Void) -> Parser<Input, Output> {
    mapError { _, error in transform(&error) }
  }

  func commit() -> Parser<Input, Output> {
    mapError { error in
      error.committed = true
    }
  }

  func commit(after distance: Int) -> Parser<Input, Output> {
    mapError { input, error in
      if input.distance(from: input.startIndex, to: error.slice.endIndex) >= distance {
        error.committed = true
      }
    }
  }

  func commit1() -> Parser<Input, Output> {
    mapError { input, error in
      if error.consumed(relativeTo: input) {
        error.committed = true
      }
    }
  }

  /// Replaces the message of an error that isn't committed and consumed nothing (see
  /// `ParseError.consumed(relativeTo:)`), typically the generic one from a failed `or`,
  /// as in `(a <|> b).expecting("Expected a or b.")`.
  ///
  /// Any other error keeps its own message, since it's already more specific than this one.
  /// That includes a token that consumed part of the input: `string("blah").expecting("Expected blah.")`
  /// on `"blab"` keeps `Expected "blah".`. To change the message regardless, use `mapError`.
  func expecting(_ message: String) -> Parser<Input, Output> {
    mapError { input, error in
      if !error.committed && !error.consumed(relativeTo: input) {
        error.message = message
      }
    }
  }
}

public func satisfy<Input: Collection & Sendable>(
  _ test: @Sendable @escaping (Input.Element) -> Bool
) -> Parser<Input, Input.Element> where Input.SubSequence: Sendable {
  Parser { (input) throws(ParseError<Input>) in
    if let elem = input.first {
      if test(elem) {
        return ParseOutput(input: input[input.index(after: input.startIndex)...], output: elem)
      } else {
        throw ParseError(reason: .nomatch, slice: input[..<input.startIndex])
      }
    } else {
      throw ParseError(reason: .eof, slice: input)
    }
  }
}

public func eq<Input: Collection & Sendable>(
  _ model: Input.Element
) -> Parser<Input, Input.Element>
  where Input.Element: Sendable & Equatable, Input.SubSequence: Sendable
{
  satisfy{ $0 == model }
}

public func or<Input: Collection & Sendable, Output>(_ parsers: [any Parsing<Input, Output>]) -> Parser<Input, Output> {
  Parser { (input) throws(ParseError<Input>) in
    for parser in parsers {
      do throws(ParseError<Input>) {
        return try parser.parse(input)
      } catch {
        guard error.committed else { continue }
        throw error
      }
    }
    throw ParseError(reason: .nomatch, slice: input[..<input.startIndex], message: "No alternative matched.")
  }
}

public func or<Input: Collection & Sendable, Output>(_ parsers: any Parsing<Input, Output>...) -> Parser<Input, Output> {
  or(parsers)
}

public func <|> <Input: Collection & Sendable, Output>(lhs: some Parsing<Input, Output>, rhs: some Parsing<Input, Output>) -> Parser<Input, Output> {
  or(lhs, rhs)
}

public func *> <Input: Collection & Sendable, Output, PrecedingOutput>(
  lhs: some Parsing<Input, PrecedingOutput>,
  rhs: some Parsing<Input, Output>
) -> Parser<Input, Output> {
  rhs.preceded(by: lhs)
}

public func <* <Input: Collection & Sendable, Output, FollowingOutput>(
  lhs: some Parsing<Input, Output>,
  rhs: some Parsing<Input, FollowingOutput>
) -> Parser<Input, Output> {
  lhs.followed(by: rhs)
}

public func just<Input: Collection & Sendable, Output>(_ value: @autoclosure @escaping @Sendable () -> Output) -> Parser<Input, Output> {
  Parser { input in
    .init(input: input, output: value())
  }
}

public func chain<Input: Collection & Sendable, Output>(_ parsers: any Parsing<Input, Output>...) -> Parser<Input, [Output]> {
  Parser { (input) throws(ParseError<Input>) in
    var outputs: [Output] = []
    var nextInput = input
    for parser in parsers {
      let output = try parser.parse(nextInput)
      outputs.append(output.output)
      nextInput = output.input
    }
    return .init(input: nextInput, output: outputs)
  }
}

public func join<Input: Collection & Sendable, Output>(_ parsers: any Parsing<Input, [Output]>...) -> Parser<Input, [Output]> {
  Parser { (input) throws(ParseError<Input>) in
    var outputs: [Output] = []
    var nextInput = input
    for parser in parsers {
      let output = try parser.parse(nextInput)
      outputs.append(contentsOf: output.output)
      nextInput = output.input
    }
    return .init(input: nextInput, output: outputs)
  }
}

public func flatten<Input: Collection & Sendable, Output>(
  _ parser: some Parsing<Input, [[Output]]>
) -> Parser<Input, [Output]> {
  parser.map { $0.flatMap { $0 } }
}

public func tuple<Input: Collection & Sendable, each Output>(
  _ parsers: repeat Parser<Input, each Output>
) -> Parser<Input, (repeat each Output)> {
  Parser { (input) throws(ParseError<Input>) in
    var rest = input
    func step<O>(_ parser: Parser<Input, O>) throws(ParseError<Input>) -> O {
      let out = try parser.parse(rest)
      rest = out.input
      return out.output
    }
    let outputs = try (repeat step(each parsers))
    return .init(input: rest, output: outputs)
  }
}

public postfix func + <Input: Collection & Sendable, Output>(parser: some Parsing<Input, Output>) -> Parser<Input, [Output]> {
  parser.many1()
}

public postfix func * <Input: Collection & Sendable, Output>(parser: some Parsing<Input, Output>) -> Parser<Input, [Output]> {
  parser.many()
}

public extension Parsers {
  static var end: Parser<Input, Void> {
    Parser { (input) throws(ParseError<Input>) in
      guard input.isEmpty else {
        throw ParseError(reason: .nomatch, slice: input[..<input.startIndex], message: "Expected end of input")
      }
      return .init(input: input, output: ())
    }
  }
}
