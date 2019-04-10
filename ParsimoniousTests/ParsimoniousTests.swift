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
    case string(String)
    case quoted(String, Bool)
    case comment(String, Bool)
    case empty // _
    case refer // &
    case select // ?
    case concat // +
    case merge // ?+
    case assign // =
    case openParens // (
    case closeParens // )
}

func tokenize(_ token: Token) -> (String) -> Token {
    return { _ in token }
}

func tokenize(_ s: String, _ token: Token) -> Parser<String, Token> {
    return tokenize(token) <*> string(s)
}

let ows = many(whitespaceOrNewline) // optional white space
let escapeChar = char("\\")
let quoteChar = char("\"")
let quotedString = (escapeChar *> (quoteChar | escapeChar)) | noneOf("\\\"")
let quoted = manyS(quotedString)
let commentChar = oneOf("{}")
let commentString = (escapeChar *> commentChar) | noneOf("{}")
let comment = manyS(commentString)

let terminatedQuoteT = {q in Token.quoted(q, true) } <*> (quoteChar *> quoted <* quoteChar)
let unterminatedQuoteT = {q in Token.quoted(q, false) } <*> (quoteChar *> quoted <* eof)
let quoteT = terminatedQuoteT | unterminatedQuoteT

let terminatedCommentT = {c in Token.comment(c, true) } <*> (char("{") *> comment <* char("}"))
let unterminatedCommentT = {c in Token.comment(c, false) } <*> (char("{") *> comment <* eof)
let commentT = terminatedCommentT | unterminatedCommentT

let tokenT = quoteT | commentT

class ParsimoniousTests: XCTestCase {

    func testParser() {
        let s = "\"bob\\\"ok\" {This is a comment!} \"Seriously?\" {No!} {Yes"
        let q = try! parse(s, with: ows *> many(tokenT <* ows) <* eof)
        print(q)
    }

}


