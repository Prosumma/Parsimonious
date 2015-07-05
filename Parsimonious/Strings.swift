//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public typealias StringParser = ParseContext -> ParseResult<String>

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

public func match(with: String) -> StringParser {
    return match(with, options: [])
}

public func regex(expression: String) -> StringParser {
    return match(expression, options: NSStringCompareOptions.RegularExpressionSearch)
}

public func matchOneOf(string: String) -> StringParser {
    return or(string.characters.map() { match(String($0)) })
}

public func match(characters: NSCharacterSet)(_ context: ParseContext) -> ParseResult<String> {
    guard let character = context.remainder[context.position...context.position].unicodeScalars.first?.value else {
        return .NotMatched
    }
    if characters.longCharacterIsMember(character) {
        defer {
            context.advance(1)
        }
        return .Matched([(context.remainder[context.position...context.position], context.position)])
    } else {
        return .NotMatched
    }
}

public func whitespace(context: ParseContext) -> ParseResult<String> {
    return match(NSCharacterSet.whitespaceCharacterSet())(context)
}

public func concat(matches: [(String, String.Index)]) -> [(String, String.Index)] {
    guard matches.count > 0 else {
        return []
    }
    let position = matches[0].1
    return [("".join(matches.map({$0.0})), position)]
}

public func trim(characterSet: NSCharacterSet)(_ string: String) -> String {
    return string.stringByTrimmingCharactersInSet(characterSet)
}

public func trim(string: String) -> String {
    return trim(NSCharacterSet.whitespaceCharacterSet())(string)
}

public func replace(target: String, withString with: String, options: NSStringCompareOptions)(_ string: String) -> String {
    return string.stringByReplacingOccurrencesOfString(target, withString: with, options: options, range: nil)
}

public func replace(target: String, withString with: String)(_ string: String) -> String {
    return string.stringByReplacingOccurrencesOfString(target, withString: with, options: [], range: nil)
}

