//
//  Optional.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-25.
//

public protocol Defaultable {
  static var defaultValue: Self { get }
}

extension Array: Defaultable {
  public static var defaultValue: Self {
    []
  }
}

public func `optional`<C: Collection, T>(
  _ parser: @escaping @Sendable @autoclosure () -> Parser<C, T>,
  default defaultValue: @escaping @Sendable @autoclosure () -> T
) -> Parser<C, T> {
  parser() <|> just(defaultValue())
}

public func `optional`<C: Collection, T: Defaultable>(
  _ parser: @escaping @Sendable @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  optional(parser(), default: .defaultValue)
}

public prefix func * <C: Collection, T: Defaultable>(
  _ parser: @escaping @Sendable @autoclosure () -> Parser<C, T>
) -> Parser<C, T> {
  optional(parser())
}

/**
 Consumes the underlying match, but discards it
 in favor of the default value.
 
 Why does it use two different types? Because it
 allows `skip` to be used in more environments.
 For example:
 
 ```swift
 chain(char(any: "abc")+, skip(eof())).joined()
 ```
 
 `eof()` returns `Void`, but embedding it in `skip`,
 the types work out.
 
 It's often easier, however, to use `<*` or `*>`, e.g.,
 
 ```swift
 char(any: "abc")+ <* eof()
 ```
 */
public func skip<C: Collection, T, S: Defaultable>(
  _ parser: @escaping @Sendable @autoclosure () -> Parser<C, T>
) -> Parser<C, S> {
  parser() *>> S.defaultValue
}
