//
//  Base.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/10/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 Succeeds if the current element in the parsed collection is `==` to `model`.
 
 - parameter type: The type of the underlying collection. Can usually be inferred and thus omitted.
 - parameter model: The model element with which to compare the current element in the parsed collection.
 */
public func satisfy<C: Collection, E: Equatable>(type: C.Type = C.self, _ model: E) -> Parser<C, E> where E == C.Element {
    return satisfy(type: type, { $0 == model })
}

/**
 Expects `parser` to succeed `range` times. In other words, if `range` is `1...7`, then `parser` must match
 at least one and at most seven times. If `range` is `0..<3`, then `parser` must match at least zero and at
 most two times.
 
 - precondition: `range.lowerBound >= 0 && range.lowerBound <= range.upperBound && range.upperBound > 0`
 
 - parameter range: A range expression.
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func count<R: RangeExpression, C: Collection, T>(_ range: R, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> where R.Bound == UInt {
    let range = range.relative(to: 0..<UInt.max)
    return count(from: range.lowerBound, to: range.upperBound - 1, parser)
}

/**
 Matches `parser` exactly `number` of times. In other words, `count(7, char("a"))` matches the letter "a" exactly 7 times.
 
 - parameter number: The exact number of times `parser` must match.
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func count<C: Collection, T>(_ number: UInt, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: number, to: number, parser)
}

/**
 Matches `parser` 0 or more times and returns the matches in an array.
 
 This parser cannot fail. If no matches are present, it simply matches an empty array.
 
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func many<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(0..., parser)
}

/**
 Matches `parser` 0 or more times and returns the matches in an array.
 
 This parser cannot fail. If no matches are present, it simply matches an empty array.
 
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public postfix func *<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return many(parser)
}

/**
 Matches `parser` 0 or more times separated by `separator` and returns the matches in an array.
 
 This parser cannot fail. If no matches are present, it simply matches an empty array.
 
 - parameter parser: The parser to match.
 - parameter separator: A parser matching a separator between each instance of `parser`.
 
 - returns: A parser giving an array of matches.
 */
public func many<C: Collection, T, S>(_ parser: @escaping Parser<C, T>, sepBy separator: @escaping Parser<C, S>) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        do {
            try values.append(context <- parser)
        } catch _ as ParsingError {
            return values
        }
        try values.append(contentsOf: context <- many(separator *> parser))
        return values
    }
}

/**
 Matches `parser` at least one time and returns the matches in an array.
 
 This parser fails if there is not at least 1 match.
 */
public func many1<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(1..., parser)
}

/**
 Matches `parser` at least one time and returns the matches in an array.
 
 This parser fails if there is not at least 1 match.
 
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public postfix func +<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return many1(parser)
}

/**
 Matches `parser` at least one time separated by `separator` and returns the matches in an array.
 
 This parser fails if there is not at least 1 match.
 
 - parameter parser: The parser to match.
 - parameter separator: A parser matching a separator between each instance of `parser`.
 
 - returns: A parser giving an array of matches.
 */
public func many1<C: Collection, T, S>(_ parser: @escaping Parser<C, T>, sepBy separator: @escaping Parser<C, S>) -> Parser<C, [T]> {
    return parser & many(separator *> parser)
}

/**
 Attempts to match at least one of the `parsers`. If none of the `parsers` succeeds,
 rethrows the last error.
 
 - note: It is usually more convenient to use the `|` combinator instead of this one. To have
 control over the error message, pass the `fail` combinator as the last parser. For example:
 
 ```
 let p = or(string("good"),
            string("bad"),
            fail("Should have matched good or bad!")
           )
 ```
 
 - parameter parsers: The array of parsers to match.
 - returns: A parser which matches at least one of the `parsers` or dies trying.
 */
public func or<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, T> {
    return or(parsers)
}

/**
 Attempts to match at least one of the `parsers`. If none of the `parsers` succeeds,
 rethrows the last error.
 
 - note: It is usually more convenient to use the `|` combinator instead of this one. To have
 control over the error message, pass the `fail` combinator as the last parser. For example:
 
 ```
 let p = string("good") |
         string("bad") |
         fail("Shoud have matched good or bad!")
 ```
 
 - parameter parsers: The array of parsers to match.
 - returns: A parser which matches at least one of the `parsers` or dies trying.
 */
public func |<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T>) -> Parser<C, T> {
    return or(lhs, rhs)
}

/**
 Matches all `parsers` in order and returns the matched values as an array.
 
 If any of the `parsers` fails, `sequence` backtracks fully and then rethrows the
 error from the failed parser.
 
 - parameter parsers: An array of parsers which must be matched in sequence.
 */
public func sequence<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, [T]> {
    return sequence(parsers)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, [T]>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, [T]>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/// Matches the parser on the left-hand side and then that on the right, returning the matches as an array.
public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

/**
 Transforms a `Parser<C, I>` into a `Parser<C, O>` by applying `transform` to it.
 
 This is often called `fmap` or `lift` in functional languages and makes `Parser` a functor.
 
 `lift` is represented by the `<%>` operator and in general this is what should be used. The use of `lift`
 is very common. For example, the `char` combinator is simply a lifted version of the `satisfy` combinator:
 
 ```
 func char(_ test: (Character) -> Bool) -> ParserS {
    return String.init <%> satisfy(test)
 }
 ```
 
 `satisfy(test)` returns a `Parser<String, Character>`, but we want to turn this into `ParserS` (`Parser<String, String>`), so
 we use `lift` to accomplish this.
 
 - parameter transform: The transform to apply.
 - parameter parser: The parser to match in order to apply the transform.
 
 - returns: A `Parser<C, O>`, where `O` is the result type of `transform`.
 */

public func <%><C: Collection, I, O>(lhs: @escaping (I) -> O, rhs: @escaping Parser<C, I>) -> Parser<C, O> {
    return lift(lhs, rhs)
}

/**
 After `parser` is matched, its value is discarded in favor of `value`.
 
 `subst` is represented by the `<=>` operator and in general this is what should be used.
 
 ```
 let t = true <=> char("t") // If this succeeds, gives true instead of "t".
 let f = false <=> char("f") // If this succeeds, gives false instead of "f".
 let bool = t | f | fail("Expected a boolean")
 ```
 
 - parameter value: The substitution value.
 - parameter parser: The parser to match.
 */
public func subst<C: Collection, I, O>(_ value: O, _ parser: @escaping Parser<C, I>) -> Parser<C, O> {
    return {_ in value} <%> parser
}

/**
 After `parser` is matched, its value is discarded in favor of `value`.
 
 `subst` is represented by the `<=>` operator and in general this is what should be used.
 
 ```
 let t = true <=> char("t") // If this succeeds, gives true instead of "t".
 let f = false <=> char("f") // If this succeeds, gives false instead of "f".
 let bool = t | f | fail("Expected a boolean")
 ```
 
 - parameter value: The substitution value.
 - parameter parser: The parser to match.
 */
public func <=><C: Collection, I, O>(lhs: O, rhs: @escaping Parser<C, I>) -> Parser<C, O> {
    return subst(lhs, rhs)
}

/**
 Attempts to match `parser`. If `parser` succeeds, `not` throws an error.
 
 The prefix operator `!` represents `not` and this is what should in general be used.
 
 ```
 char("s") <* !char("i")
 ```
 
 Matches the character "s" unless followed by "i".
 
 This parser never consumes any of the underlying collection, whether it succeeds or fails.
 
 - parameter parser: The `parser` to match.
 */
public func not<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, Void> {
    return { context in
        try context <- peek(parser)
        throw context.fail("Negative match failed.")
    }
}

/**
 Attempts to match `parser`. If `parser` succeeds, `not` throws an error.
 
 The prefix operator `!` represents `not` and this is what should in general be used.
 
 ```
 char("s") <* !char("i")
 ```
 
 Matches the character "s" unless followed by "i".
 
 This parser never consumes any of the underlying collection, whether it succeeds or fails.
 
 - parameter parser: The `parser` to match.
 - parameter error: An optional error to throw. If omitted, a `ParseError` with the message "Negative match failed." is thrown.
 */

public prefix func !<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, Void> {
    return not(parser)
}

/**
 Matches both `lparser` and `rparser`, but "returns" only the value matched by the former. The two parsers
 do not need to be of the same type.
 
 This parser is chiefly used when one match must be followed by another, but we are only interested
 in the value of the first match. `first` is typically used as an operator, `<*`.
 
 ```
 let item = many1S(\Character.isLetter) <* many1(\Character.isWhitespace)
 ```
 
 When `item` is applied, we'll get back only the letters in the item. At least one whitespace character
 _must_ occur after `item`. Without it, the `item` parser will fail. But the whitespace is discarded.
 */
public func <*<C: Collection, L, R>(lparser: @escaping Parser<C, L>, rparser: @escaping Parser<C, R>) -> Parser<C, L> {
    return first(lparser, rparser)
}

/**
 Matches both `lparser` and `rparser`, but "returns" only the value matched by the latter. The two parsers
 do not need to be of the same type.
 
 This parser is chiefly used when one match must be followed by another, but we are only
 interested in the value of the second match. `second` is typically used as an operator, `*>`.
 
 ```
 let item = many1(\Character.isWhitespace) *> many1S(\Character.isLetter)
 ```
 
 When `item` is applied, we'll get back only the letters in the item. At least one whitespace character _must_
 occur before `item`. Without it, the `item` parser will fail. But the whitespace is discarded.
 */
public func *><C: Collection, L, R>(lparser: @escaping Parser<C, L>, rparser: @escaping Parser<C, R>) -> Parser<C, R> {
    return second(lparser, rparser)
}

/**
 Unconditionally consumes the next element in the underlying collection. Fails only
 on EOF.
 
 - throws: `ParseError` on EOF
 - parameter context: The context wrapping the consumed collection.
 - returns: The consumed element.
 */
public func accept<C: Collection>(_ context: Context<C>) throws -> C.Element {
    return try context <- satisfy{ _ in true }
}

