//
//  Match.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 Matches using the `range(of:options:range:locale:)` method of `String`.
 
 - warning: This method is *very* slow. Exhaust all other reasonable
 possibilities before using it.
 
 - parameter test: The string to use for matching.
 - parameter options: The match options.
 
 - returns: A parser which performs matching according to the passed-in parameters.
 */
func match(_ test: String, options: String.CompareOptions = []) -> ParserS {
    var options = options
    options.insert(.anchored)
    return { context in
        guard let rest = context.rest else {
            throw ParseError(message: "Expected to match a string against '\(test)', but got EOF.", context: context, inner: ErrorCode.eof)
        }
        guard let range = rest.range(of: test, options: options, range: nil, locale: nil) else {
            throw ParseError(message: "Expected to match a string against '\(test)', but the match failed.", context: context, inner: ErrorCode.unexpected)
        }
        let matched = rest[range]
        context.offset(by: matched)
        return String(matched)
    }
}

/**
 Attempts to match a specific string.
 
 - note: This method does _not_ use `match` under the hood and
 has reasonably good performance.
 */
public func string(_ test: String, ignoringCase: Bool = false) -> ParserS {
    let parsers = ignoringCase ? test.map(char << ichar) : test.map(char)
    return concat(parsers) | fail("Expected to match \"\(test)\".")
}

/**
 Uses `match` to attempt a regular expression match.
 
 - warning: Avoid if possible. Parser combinators obviate the need
 for regular expressions and in most cases are faster.
 */
public func regex(_ test: String, ignoringCase: Bool = false) -> ParserS {
    let options: String.CompareOptions = ignoringCase ? [.caseInsensitive, .regularExpression] : .regularExpression
    return match(test, options: options)
}
