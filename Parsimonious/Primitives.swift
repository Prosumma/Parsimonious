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
    case .NotMatched:
        return .Matched([])
    default:
        return parseResult
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

public func skip<T1, T2>(parser: ParseContext -> ParseResult<T1>)(_ context: ParseContext) -> ParseResult<T2> {
    switch parser(context) {
    case .Matched(_): return .Matched([])
    case .NotMatched: return .NotMatched
    case let .Error(error, position): return .Error(error, position)
    }
}

public func some<T>(range: Range<UInt>)(_ parser: ParseContext -> ParseResult<T>)(_ context: ParseContext) -> ParseResult<T> {
    let position = context.position
    let parseResult = parser(context)
    switch parseResult {
    case .Matched(let matches):
        let count = UInt(matches.count)
        if count >= range.startIndex && count < range.endIndex {
            return parseResult
        } else {
            context.position = position
            return .NotMatched
        }
    default:
        return parseResult
    }
}

public func some<T>(count: UInt) -> (ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return some(count...count)
}

public func some<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return some(1..<UInt.max)(parser)
}

public func expect<T>(parser: ParseContext -> ParseResult<T>, error: ErrorType)(_ context: ParseContext) -> ParseResult<T> {
    let parseResult = parser(context)
    switch parseResult {
    case .NotMatched: return .Error(error, context.position)
    default: return parseResult
    }
}

public func lift<T1, T2>(parser: ParseContext -> ParseResult<T1>, transform: [(T1, Range<String.Index>)] -> [(T2, Range<String.Index>)])(_ context: ParseContext) -> ParseResult<T2> {
    switch parser(context) {
    case .Matched(let matches): return .Matched(transform(matches))
    case .NotMatched: return .NotMatched
    case let .Error(error, position): return .Error(error, position)
    }
}

public func lift<T1, T2>(parser: ParseContext -> ParseResult<T1>, transform: T1 -> T2)(_ context: ParseContext) -> ParseResult<T2> {
    switch parser(context) {
    case .Matched(let matches): return .Matched(matches.map() { (transform($0.0), $0.1) })
    case .NotMatched: return .NotMatched
    case let .Error(error, position): return .Error(error, position)
    }
}

public func end<T>(context: ParseContext) -> ParseResult<T> {
    return context.position == context.string.endIndex ? .Matched([]) : .NotMatched
}