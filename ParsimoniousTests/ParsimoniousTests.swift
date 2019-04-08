//
//  ParsimoniousTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2/28/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

let ows = manyS(whitespace | newline)
let ws = many1S(whitespace | newline)
let sep = ws | (ows + char(",") + ows)
let quoted = string(delimitedBy: "\"")

class ParsimoniousTests: XCTestCase {

    func testParser() {
        let s = "\"ok\",\"yes\" \"crazy\"  "
        let quotes = try! parse(string: s, with: ows *> many(quoted, sepBy: sep) <* ows <* eof)
        print(quotes)
    }

}


