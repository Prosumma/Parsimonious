//
//  ParsimoniousTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2/28/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

enum Token {
    case name(String)
    case quotation(String, Bool)
    case garbage
}

func quotation(_ context: Context<String>) throws -> Token {
    let escape: Character = "\\"
    let quote: Character = "\""
    let escapeChar = char(escape)
    let quoteChar = char(quote)
    let q = quoteChar *> manyS((escapeChar *> (quoteChar | escapeChar)) | noneOf(escape, quote))
    return try context.transact {
        let t = try q(context)
        do {
            try context <- quoteChar
            return Token.quotation(t, true)
        } catch {
            return Token.quotation(t, false)
        }
    }
}

func identifier(_ name: String) -> ParserS {
    return string(name, ignoringCase: true) <* (ws | peek(satisfyChar(\Character.isPunctuation)))
}

let quoteName = Token.name <*> (satisfyChar(\Character.isLetter) + manyS(any: \Character.isLetter, \Character.isNumber) <* ws)

let ows = manyS(\Character.isWhitespace)
let ws = many1S(\Character.isWhitespace)

let whitespaceAndNotNewline = satisfyChar(all: \Character.isWhitespace, !\Character.isNewline)
let alphaNum = satisfyChar(any: \Character.isLetter, \Character.isNumber)

class ParsimoniousTests: XCTestCase {

    func testParser() {
        let s = """
        QUOTES today

"what?", "That's CRAZY, man!


",

"Yep!"
"""
        let sep = ows *> char(",") <* ows
        let qs = try! parse(s, with: ows *> identifier("QUOTES") *> sequence(quoteName, many1(quotation, sepBy: sep)) <* eof)
        print(qs)
    }

}

