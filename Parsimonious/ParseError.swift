//
//  ParseError.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 A marker protocol indicating a parsing error.
 Combinators such as `|` look for this marker
 protocol when deciding whether to handle the
 error or rethrow it.
 
 Parsimonious has only one class that implements
 this protocol: `ParseError`.
 
 See the documentation for `ParseError` on
 the philosophy behind errors and error handling
 in Parsimonious.
 */
public protocol ParsingError: Error {}

/**
 An error that occurs as a result of parser failure.
 
 There really only is one kind of parser failure: a parser was not satisfied.
 _Why_ it was not satisfied is a mere detail, but there are really only two
 possibilities. In the first case, something unexpected was encountered and
 the parser failed to match. In the second case, EOF was encountered and the
 parser failed to match. This is true even in the case of a `count` combinator
 whose count was unsatisfied. If we say `count(7, parser)` but the underlying
 parser was only matched 6 times, we must ask why it was only matched 6 times.
 There are only two possibilites: something unexpected or EOF.
 
 Why throw errors at all? A parser is a function with the signature
 `(Context<C>) throws -> T`. The return type of a parser is the value matched,
 so we indicate failure with an error. Instead of this, we might have defined
 a parser as `(Context<C>) -> Result<T, Error>`. This certainly would have
 worked, but the problem is the greater ceremony required to deal with it. It
 is primarily for this reason that parsers throw errors. By throwing errors,
 we can use much more natural syntax to backtrack when a parser fails, e.g.,
 
 ```
 func match<C, T>(_ parsers: Parser<C, T>...) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        for parser in parsers {
            try values.append(context <- parser)
        }
        return values
    }
 }
 ```
 
 In the example above any error thrown by `try` simply escapes the current
 scope and is propagated up. This is exactly what we want and is very
 natural in Swift.
 
 Parsers begin parsing at a certain position in the underlying collection.
 When a parser fails, it rewinds to the position at which it started and
 then throws a `ParseError`.
 
 Some combinators swallow `ParseError`s. For instance, the `optional` combinator
 swallows any underlying `ParseError` and returns an optional, e.g.,
 
 ```
 let s: String? = try context <- optionalS(string("ok"))
 ```
 
 If the string "ok" is not matched, then `s` will be `nil`. The `|` combinator
 swallows the `ParseError` thrown by the left-hand side but not by the right-hand
 side:
 
 ```
 char("a") | char("e")
 ```
 
 If the character "a" fails to match, then `|` will attempt to match "e", if that fails then
 the `ParseError` will be allowed to propagate. Very often it is best to use the `fail` combinator
 in this situation to make the error clearer:
 
 ```
 char("a") | char("e") | fail("Tried and failed to match a or e.")
 ```
 */
public struct ParseError<Contents: Collection>: ParsingError {
    /// An optional, purely informational message.
    public let message: String?
    /**
     The index in the collection at which some parser failed
     to match.
     */
    public let index: Contents.Index

    /// An inner error, if any.
    public let inner: Error?

    /**
     Initializes a `ParseError`.
     
     - parameter index: The index at which some parser failed to match.
     - parameter message: An optional, purely informational message.
     */
    public init(_ index: Contents.Index, message: String? = nil, inner: Error? = nil) {
        self.index = index
        self.message = message
        self.inner = inner
    }
    
}

public func <?><C: Collection, T>(parser: @escaping Parser<C, T>, error: String) -> Parser<C, T> {
    return parser | fail(error)
}
