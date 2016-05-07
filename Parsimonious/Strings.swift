//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public typealias StringParser = ParseContext -> ParseResult<String>

public func match(with: String, options: NSStringCompareOptions) -> (ParseContext -> ParseResult<String>) {
    return { context in
        var options = options
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
        return .Matched([(context.remainder[range], context.position..<context.position.advancedBy(range.startIndex.distanceTo(range.endIndex)))])
    }
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

public func match(characters: NSCharacterSet) -> (ParseContext -> ParseResult<String>) {
    return { context in
        guard let character = context.remainder.characters.first else {
            return .NotMatched
        }
        let s = String(character)
        if let range = s.rangeOfCharacterFromSet(characters) {
            defer {
                context.advance(1)
            }
            return .Matched([(s, context.position..<context.position.advancedBy(1))])
        } else {
            return .NotMatched
        }
    }
}

public func whitespace(context: ParseContext) -> ParseResult<String> {
    return match(NSCharacterSet.whitespaceCharacterSet())(context)
}

public func concat(matches: [(String, Range<String.Index>)]) -> [(String, Range<String.Index>)] {
    guard matches.count > 0 else {
        return []
    }
    let start = matches[0].1.startIndex
    let end = matches.last!.1.endIndex
    return [(matches.map({$0.0}).joinWithSeparator(""), start..<end)]
}

public func trim(characterSet: NSCharacterSet) -> (String -> String) {
    return { string in string.stringByTrimmingCharactersInSet(characterSet) }
}

public func trim(string: String) -> String {
    return trim(NSCharacterSet.whitespaceCharacterSet())(string)
}

public func replace(target: String, withString with: String, options: NSStringCompareOptions) -> (String -> String) {
    return { string in string.stringByReplacingOccurrencesOfString(target, withString: with, options: options, range: nil) }
}

public func replace(target: String, withString with: String) -> (String -> String) {
    return { string in string.stringByReplacingOccurrencesOfString(target, withString: with, options: [], range: nil) }
}

