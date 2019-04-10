//
//  ParsimoniousTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2/28/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

indirect enum Comment {
    case string(String)
    case comments([Comment], Bool)
    
    var comment: String {
        switch self {
        case .string(let s): return s
        case let .comments(comments, terminated): return "{" + comments.map{ $0.comment }.joined() + (terminated ? "}" : "")
        }
    }
}

let ows = many(whitespaceOrNewline) // optional white space
let escapeChar = char("\\")

func comment(_ context: Context<String>) throws -> Comment {
    let commentChar = (escapeChar *> oneOf("{}\\")) | noneOf("{}")
    let commentString = Comment.string <*> many1S(commentChar)
    return try context.transact {
        try context <- char("{")
        var comments: [Comment] = []
        while true {
            do {
                try comments.append(context <- (comment | commentString))
            } catch {
                break
            }
        }
        let term = try? context <- char("}")
        return .comments(comments, term != nil)
    }
}

enum Quoting {
    case none
    case terminated
    case unterminated
}

let quote = char("\"")
let quoteChar = (escapeChar *> quote) | noneOf("\"")
let unterminatedQuotation = quote *> manyS(quoteChar) <* eof
let terminatedQuotation = quote *> manyS(quoteChar) <* quote
let unquotedChar = satisfyS(all: !\.isWhitespace, !"\"", !"{", !"}", !"\\", !"+", !"?", !"=", !"&", !"(", !")")
let unquoted = many1S(unquotedChar)
let garbage = many1S(satisfyS(!\.isWhitespace))

enum Token {
    case comment(Comment)
    case string(String, Quoting)
    case garbage(String)
    case empty
    case open // (
    case close // )
    case refer // &
    case select // ?
    case assign // =
}

typealias Tokenizer = (String) -> Token

func tokenize(_ token: Token) -> Tokenizer {
    return {_ in token}
}

func tokenize(_ character: Character, _ token: Token) -> Parser<String, Token> {
    return tokenize(token) <*> char(character)
}

let commentT = Token.comment <*> comment
let unterminatedQuotationT = {q in Token.string(q, .unterminated)} <*> unterminatedQuotation
let terminatedQuotationT = {q in Token.string(q, .terminated)} <*> terminatedQuotation
let unquotedT = {s in Token.string(s, .none)} <*> unquoted
let stringT = terminatedQuotationT | unterminatedQuotationT | unquotedT
let emptyT = tokenize(.empty) <*> (many1S(char("_")) <* peek(whitespaceOrNewline | oneOf("(){\"+?=&") | eofS))
let garbageT = Token.garbage <*> garbage
let openT = tokenize("(", .open)
let closeT = tokenize(")", .close)
let referT = tokenize("&", .refer)
let selectT = tokenize("?", .select)
let assignT = tokenize("=", .assign)

let tokenT = or(emptyT, stringT, commentT, openT, closeT, selectT, referT, assignT, garbageT)

class ParsimoniousTests: XCTestCase {

    func testParser() {
        let s = "_asshattery_ _11(crazy)=&\"What's \\\"this?\"  ging_   {This is a simple comment. {And this is a nested comment. {And this, too!}}} {What?}      "
        let cs = try! parse(s, with: ows *> many(tokenT <* ows) <* eof)
        print(cs)
    }

}


