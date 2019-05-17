//
//  ParsimoniousFQNameTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 5/12/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import Parsimonious

let letter = char(i("abcdefghijklmnopqrstuvwxyz"))
let underscore = char("_")
let digit = char("0123456789")
let ename = (letter | underscore) + manyS(letter | digit | underscore)
let fqname = ename + manyS(char(".") + ename)
let enames = many(ename, sepBy: char("."))
let fqnames = many(fqname, sepBy: ws)

class ParsimoniousFQNameTests: XCTestCase {
    func testParseFQName() {
        let fqn = try! parse("vendita.oracle.oda0100.checkpoint foo.bar.baz bada.bing.bada.BOOM", with: fqnames <* eof)
        print(fqn)
    }
}
