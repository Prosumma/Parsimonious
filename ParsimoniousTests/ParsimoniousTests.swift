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
    case quotation(String)
    case garbage
}

let escape: Character = "\\"
let quote: Character = "\""

let escapeChar = char(escape)
let quoteChar = char(quote)

let quotation = quoteChar *> manyS((escapeChar *> (quoteChar | escapeChar)) | noneOf(escape, quote)) <* quoteChar

let wsnotab = satisfyChar(all: \Character.isWhitespace, !"\t")

let ows = manyS(\Character.isWhitespace)
let ws = many1S(\Character.isWhitespace)
let wsnonl = many1S(all: \Character.isWhitespace, !\Character.isNewline)
let wsnotabs = manyS(wsnotab)

func delimit(_ parser: @escaping ParserS, between start: @escaping ParserS, and end: @escaping ParserS) -> ParserS {
    return start *> ows *> parser <* ows <* end
}

func parens(_ parser: @escaping ParserS) -> ParserS {
    return delimit(parser, between: char("("), and: char(")"))
}

class ParsimoniousTests: XCTestCase {

    func testParser() {
        let s = """
"what?" "That's CRAZY, man!"
"""
        let qs = try! parse(s, with: many(position(Token.quotation <*> ((quotation | parens(quotation)) <* (ws | eofS)))) <* eof)
        print(qs)
    }

}

