//
//  Prim.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/10/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 The fundamental combinator. Tests the current element in the underlying collection and matches it if it passes `test`.
 
 `sastify` is used as the basis for a great many other combinators.
 
 - note: If you want to match individual characters and the underlying `Collection` is a `String`, it's best to use one of the
 `ParserS` combinators, such as `char` or `manyS` or `many1S`.
 
 In some contexts, it may be necessary to provide the `type` parameter in order to give type evidence.
 
 - parameter type: The type of the underlying collection. Can usually be inferred and thus omitted.
 - parameter test: A predicate which takes a single element of the collection and tests it. If true, the element is matched.
 
 - returns: A parser of type `Parser<C, E>`.
 */
public func satisfy<C: Collection, E>(type: C.Type = C.self, _ test: @escaping (E) -> Bool) -> Parser<C, E> where E == C.Element {
    return { context in
        guard let e = context.next else {
            throw ParseError(context)
        }
        if test(e) {
            context.offset(by: 1)
            return e
        } else {
            throw ParseError(context)
        }
    }
}

/**
 Attempts to match `parser` at least `from` and at most `to` times. Matches an array.
 
 - note: This combinator underlies all parsers that attempt some quantity or range of matches, such as `many`, `many1`, `manyS`, etc.
 
 Direct use of this combinator should be avoided. Instead, use `many`, `many1`, or one of the overloads that takes an `Int` or range type.
 
 - precondition: `from >= 0 && from <= to && to > 0`
 
 - parameter from: The minimum number of matches permitted.
 - parameter to: The maximum number of matches permitted.
 - parameter parser: The parser to match.
 
 - returns: A parser of type `Parser<C, [T]>` which matches an array of the matched type.
 */
public func count<C: Collection, T>(from: UInt, to: UInt, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {    
    assert(from >= 0 && from <= to && to > 0, "Invalid range for count. Valid for from and to are: from >= 0 && from <= to && to > 0.")
    return transact { context in
        var values: [T] = []
        while values.count < from {
            do {
                try values.append(parser(context))
            } catch let e as ParsingError {
                if from == to {
                    throw ParseError(context, message: "Expected \(to) but got \(values.count).", inner: e)
                } else if to >= UInt.max - 1 {
                    throw ParseError(context, message: "Expected at least \(from) but got \(values.count).", inner: e)
                } else {
                    throw ParseError(context, message: "Expected at least \(from) and at most \(to), but got \(values.count).", inner: e)
                }
            }
        }
        while values.count < to {
            do {
                let value = try parser(context)
                values.append(value)
            } catch _ as ParsingError {
                break
            }
        }
        return values
    }
}

/**
 Attempts to match at least one of the `parsers`. If none of the `parsers` succeeds,
 rethrows the last error.
 
 - note: It is usually more convenient to use the `|` combinator instead of this one. To have
 control over the error message, pass the `fail` combinator as the last parser. For example:
 
 ```
 let p = or([string("good"),
             string("bad"),
             fail("Should have matched good or bad!")
            ])
 ```
 
 - parameter parsers: The array of parsers to match.
 - returns: A parser which matches at least one of the `parsers` or dies trying.
 */
public func or<C: Collection, T>(_ parsers: [Parser<C, T>]) -> Parser<C, T> {
    assert(parsers.count > 0, "The 'or' combinator requires at least one parser.")
    return { context in
        if (parsers.count == 1) {
            return try parsers[0](context)
        } else {
            var lastError: ParsingError!
            for parser in parsers {
                do {
                    return try parser(context)
                } catch let error as ParsingError {
                    lastError = error
                }
            }
            // The only way we can get here is if the last parser fails.
            throw lastError
        }
    }
}

/**
 The lookahead combinator. Attempts to match `parser` and throws a `ParseError` if it fails. Either way,
 `peek` backtracks as if the `parser` was never matched.
 
 For example, imagine we are parsing a list of whitespace-separated items. Each element in the list must
 be followed by whitespace except in the case where it is followed by `)`. However, this `)` must also
 be parsed by a parser at a higher level, so we only want to "peek" to see if it is there.
 
 ```
 let ws = many1S(\Character.isWhitespace)
 let ows = manyS(\Character.isWhitespace)
 let item = many1S(\Character.isLetter)
 let items = many(item <* (ws | peek(char(")")))) // This is where we peek.
 let parens = char("(") *> (items <*> ws) <* char(")")
 ```

 - parameter parser: The parser to match.
 */
public func peek<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T> {
    return { context in
        context.saveIndex()
        defer { context.restoreIndex() }
        return try parser(context)
    }
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
public func lift<C: Collection, I, O>(_ transform: @escaping (I) -> O, _ parser: @escaping Parser<C, I>) -> Parser<C, O> {
    return { context in
        return try transform(parser(context))
    }
}

/**
 This combinator always fails and throws a `ParseError` with `message`.
 
 This combinator is used to provide better error messages, usually in conjunction with `|`, e.g.,
 
 ```
 char("a") | fail("Hey man! Where's my 'a'?")
 ```
 
 This can be expressed even more succinctly using the `<?>` combinator:
 
 ```
 char("a") <?> "Hey man! Where's my 'a'?"
 ```
 
 - parameter message: The error message to throw.
 - parameter type: In the very rare case where type evidence is needed, it can be provided here.
 */
public func fail<C: Collection, T>(_ message: @escaping @autoclosure () -> String, type: C.Type = C.self) -> Parser<C, T> {
    return { context in
        throw ParseError(context, message: message())
    }
}

public func fail<C: Collection, T>(_ makeMessage: @escaping (C.SubSequence?) -> String, type: C.Type = C.self) -> Parser<C, T> {
    return { context in
        let message = makeMessage(context.rest)
        throw ParseError(context, message: message)
    }
}

/**
 Attempts to match using `parser`, but matches `nil` if `parser` fails.
 
 - note: If attempting to match zero or more times, it is best to use the `many`
 combinator instead, which returns a `Parser<C, [T]>`. If an array is more convenient,
 use `count(0...1, parser)` instead, which returns an empty array if there is no match.

 - parameter parser: The parser to use for matching.
 */
public func optional<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T?> {
    return { context in
        do {
            return try parser(context)
        } catch _ as ParsingError {
            return nil
        }
    }
}

/**
 Attempts to match using `parser`, but returns `defaultValue` if `parser` does not match.
 
 - parameter parser: The parser to use for matching.
 - parameter defaultValue: The value to use if `parser` does not match.
 */
public func optional<C: Collection, T>(_ parser: @escaping Parser<C, T>, default defaultValue: @escaping @autoclosure () -> T) -> Parser<C, T> {
    return { context in
        do {
            return try parser(context)
        } catch _ as ParsingError {
            return defaultValue()
        }
    }
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
public func first<C: Collection, L, R>(_ lparser: @escaping Parser<C, L>, _ rparser: @escaping Parser<C, R>) -> Parser<C, L> {
    return transact { context in
        let value = try lparser(context)
        _ = try rparser(context)
        return value
    }
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
public func second<C: Collection, L, R>(_ lparser: @escaping Parser<C, L>, _ rparser: @escaping Parser<C, R>) -> Parser<C, R> {
    return { context in
        _ = try lparser(context)
        return try rparser(context)
    }
}

/**
 Matches all `parsers` in order and returns the matched values as an array.

 If any of the `parsers` fails, `sequence` backtracks fully and then rethrows the
 error from the failed parser.
 
 - parameter parsers: An array of parsers which must each be matched in sequence.
 */
public func sequence<C: Collection, T>(_ parsers: [Parser<C, T>]) -> Parser<C, [T]> {
    return transact { context in
        return try parsers.map{ parser in try parser(context) }
    }
}

/**
 Matches first a `Parser<C, T>` and then a `Parser<C, T?>`. If the value matched by the second parser
 is non-nil, it is included in the "returned" array. In other words, the array will either have 1 or 2
 elements.
 */
public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T>, _ rparser: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        var values = [try lparser(context)]
        if let value = try rparser(context) {
            values.append(value)
        }
        return values
    }
}

/**
 Matches first a `Parser<C, T?>` and then a `Parser<C, T>`. If the value matched by the first parser
 is non-nil, it is included in the "returned" array. In other words, the array will either have 1 or 2
 elements.
 */
public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T?>, _ rparser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        if let value = try lparser(context) {
            values.append(value)
        }
        try values.append(rparser(context))
        return values
    }
}

/// Matches first a `Parser<C, [T]>` and then a `Parser<C, T>`, combining this into a result of `[T]`.
public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, [T]>, _ rparser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values = try lparser(context)
        try values.append(rparser(context))
        return values
    }
}

/// Matches first a `Parser<C, T>` and then a `Parser<C, [T]>`, combining this into a result of `[T]`.
public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T>, _ rparser: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return transact { context in
        let value = try lparser(context)
        var values = try rparser(context)
        values.insert(value, at: 0)
        return values
    }
}

/// Matches first a `Parser<C, [T]>` and then a `Parser<C, T?>`, combining this into a result of `[T]`.
public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, [T]>, _ rparser: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        var values = try lparser(context)
        if let value = try rparser(context) {
            values.append(value)
        }
        return values
    }
}

/// Matches first a `Parser<C, T?>` and then a `Parser<C, [T]>`, combining this into a result of `[T]`.
public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T?>, _ rparser: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return transact { context in
        let value = try lparser(context)
        var values = try rparser(context)
        if let value = value {
            values.insert(value, at: 0)
        }
        return values
    }
}

/**
 Matches the end of input.
 
 This combinator always returns `Void`. The best way to use it is with the `<*` combinator:
 
 ```
 many(acceptChar) <* eof
 ```
 
 - warning: This is the only combinator that can be matched an unlimited number of times.
 Never use `eof` in an expression such as `many(eof)` because it may never terminate.
 */
public func eof<C: Collection>(_ context: Context<C>) throws {
    if !context.atEnd {
        throw ParseError(context, message: "Expected EOF.")
    }
}

