//
//  Options.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public func withOptions<T>(parser: ParseContext -> ParseResult<T>, options: ParseOptions)(_ context: ParseContext) -> ParseResult<T> {
    context.pushOptions(options)
    defer {
        context.popOptions()
    }
    return parser(context)
}

public func skipWhitespace<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return withOptions(parser, options: ParseOptions(skipCharacters: Optional.Some(NSCharacterSet.whitespaceCharacterSet()), caseInsensitive: nil))
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

