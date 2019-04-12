//
//  Match.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

func match(_ test: String, options: String.CompareOptions = []) -> ParserS {
    var options = options
    options.insert(.anchored)
    return { context in
        guard let rest = context.rest else {
            throw ParseError(message: "Expected to match a string against '\(test)', but got EOF.", context: context)
        }
        guard let range = rest.range(of: test, options: options, range: nil, locale: nil) else {
            throw ParseError(message: "Expected to match a string against '\(test)', but the match failed.", context: context)
        }
        let matched = rest[range]
        context.offset(by: matched)
        return String(matched)
    }
}

public func string(_ test: String, ignoringCase: Bool = false) -> ParserS {
    let options: String.CompareOptions = ignoringCase ? .caseInsensitive : []
    return match(test, options: options)
}

public func regex(_ test: String, ignoringCase: Bool = false) -> ParserS {
    let options: String.CompareOptions = ignoringCase ? [.caseInsensitive, .regularExpression] : .regularExpression
    return match(test, options: options)
}


