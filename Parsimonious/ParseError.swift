//
//  ParseError.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 A marker protocol indicates a parsing error.
 Combinators such as `|` look for this marker
 protocol when deciding whether to handle the
 error or rethrow it.
 */
public protocol ParsingError: Error {}

public enum ErrorCode: ParsingError {
    case eof
    case unexpected
    case tooFew
}

/**
 An error that occurs as a result of parser failure.
 
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
    public let message: String
    public let contents: Contents
    public let index: Contents.Index
    public let inner: Error?
    
    public init(message: String, contents: Contents, index: Contents.Index, inner: Error? = nil) {
        self.message = message
        self.contents = contents
        self.index = index
        self.inner = inner
    }
}

public func <?><C: Collection, T>(parser: @escaping Parser<C, T>, error: String) -> Parser<C, T> {
    return parser | fail(error)
}
