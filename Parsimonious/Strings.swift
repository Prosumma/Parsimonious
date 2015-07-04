//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public func match(with: String, var options: NSStringCompareOptions)(_ context: ParseContext) -> ParseResult<String> {
    options = options.union(NSStringCompareOptions.AnchoredSearch)
    if context.options.caseInsensitive {
        options = options.union(NSStringCompareOptions.CaseInsensitiveSearch)
    }
    guard let range = context.remainder.rangeOfString(with, options: options, range: nil, locale: nil) else {
        return .NotMatched
    }
    defer {
        context.advance(range)
    }
    return .Matched([(context.remainder[range], context.position)])
}

public func match(with: String) -> ParseContext -> ParseResult<String> {
    return match(with, options: [])
}

public func regex(expression: String) -> ParseContext -> ParseResult<String> {
    return match(expression, options: NSStringCompareOptions.RegularExpressionSearch)
}

