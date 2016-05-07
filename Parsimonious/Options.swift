//
//  Options.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public func withOptions<T>(parser: ParseContext -> ParseResult<T>, options: ParseOptions) -> (ParseContext -> ParseResult<T>) {
    return { context in
        context.pushOptions(options)
        defer {
            context.popOptions()
        }
        return parser(context)
    }
}

public func skip<T>(skipCharacters: NSCharacterSet) -> ((ParseContext -> ParseResult<T>) -> (ParseContext -> ParseResult<T>)) {
    return { parser in
        return withOptions(parser, options: ParseOptions(skipCharacters: Optional.Some(skipCharacters), caseInsensitive: nil))
    }
}

public func skipWhitespace<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return skip(NSCharacterSet.whitespaceCharacterSet())(parser)
}

public func skipWhitespaceAndNewlines<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return skip(NSCharacterSet.whitespaceAndNewlineCharacterSet())(parser)
}

public func skipNothing<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return withOptions(parser, options: ParseOptions(skipCharacters: Optional.Some(nil), caseInsensitive: nil))
}

public func caseInsensitive<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return withOptions(parser, options: ParseOptions(skipCharacters: nil, caseInsensitive: true))
}

public func caseSensitive<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return withOptions(parser, options: ParseOptions(skipCharacters: nil, caseInsensitive: false))
}
