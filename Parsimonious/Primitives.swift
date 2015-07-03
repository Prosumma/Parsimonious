//
//  Primitives.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public func opt<T>(parser: ParseContext -> ParseResult<T>)(_ context: ParseContext) -> ParseResult<T> {
    let parseResult = parser(context)
    switch parseResult {
    case .NotMatched: return .Matched([])
    default: return parseResult
    }
}

public func not<T>(parser: ParseContext -> ParseResult<T>)(_ context: ParseContext) -> ParseResult<T> {
    let position = context.position
    let parseResult = parser(context)
    switch parseResult {
    case .Matched(_):
        context.position = position
        return .NotMatched
    default: return parseResult
    }
}

public func and<T>(parsers: [ParseContext -> ParseResult<T>])(_ context: ParseContext) -> ParseResult<T> {
    guard parsers.count > 0 else {
        return .NotMatched
    }
    let position = context.position
    var matches = Array<ParseResult<T>.Match>()
    for parser in parsers {
        switch parser(context) {
        case .Matched(let partialMatches):
            matches += partialMatches
        case .NotMatched:
            context.position = position
            return .NotMatched
        case .Error(let error):
            return .Error(error)
        }
    }
    return .Matched(matches)
}

public func and<T>(parsers: (ParseContext -> ParseResult<T>)...) -> ParseContext -> ParseResult<T> {
    return and(parsers)
}

public func or<T>(parsers: [ParseContext -> ParseResult<T>])(_ context: ParseContext) -> ParseResult<T> {
    guard parsers.count > 0 else {
        return .NotMatched
    }
    for parser in parsers {
        let parseResult = parser(context)
        switch parseResult {
        case .NotMatched: continue
        default: return parseResult
        }
    }
    return .NotMatched
}

public func or<T>(parsers: (ParseContext -> ParseResult<T>)...) -> ParseContext -> ParseResult<T> {
    return or(parsers)
}

public func many<T>(parser: ParseContext -> ParseResult<T>)(_ context: ParseContext) -> ParseResult<T> {
    var matches = Array<ParseResult<T>.Match>()
    parsing: while true {
        switch parser(context) {
        case .Matched(let partialMatches): matches += partialMatches
        case .NotMatched: break parsing
        case .Error(let error): return .Error(error)
        }
    }
    return .Matched(matches)
}

public func skip<T>(parser: ParseContext -> ParseResult<T>)(_ context: ParseContext) -> ParseResult<T> {
    let parseResult = parser(context)
    switch parseResult {
    case .Matched(_): return .Matched([])
    default: return parseResult
    }
}

public func some<T>(range: Range<UInt>)(_ parser: ParseContext -> ParseResult<T>)(_ context: ParseContext) -> ParseResult<T> {
    let position = context.position
    let parseResult = parser(context)
    switch parseResult {
    case .Matched(let matches):
        if range.contains(UInt(matches.count)) {
            return parseResult
        } else {
            context.position = position
            return .NotMatched
        }
    default:
        return parseResult
    }
}

public func some<T>(count: UInt) -> (ParseContext -> ParseResult<T>) -> (ParseContext -> ParseResult<T>) {
    return some(count...count)
}

public func some<T>(parser: ParseContext -> ParseResult<T>) -> (ParseContext -> ParseResult<T>) {
    return some(1..<UInt.max)(parser)
}

