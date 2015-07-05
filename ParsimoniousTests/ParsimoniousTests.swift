//
//  ParsimoniousTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import XCTest

class ParsimoniousTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCSV() {
        let quote = match <* "\""
        let comma = match <* ","
        let skipQuote: StringParser = skip <* quote
        let skipComma: StringParser = skip <* comma
        let emptyQuotes = match <* "\"\"" *> { _ in "" }
        let unquoted = regex <* "[^\",]*" *> trim
        let quoteChunk = regex <* "[^\"\\\\]*\\\\\""
        let quotedText = quoteChunk | (regex <* "[^\"]+")
        let quoted = emptyQuotes | (skipQuote & quotedText+ & skipQuote) *> concat *> replace("\\\"", withString: "\"")
        let field = skipNothing <* (quoted | unquoted)
        let csv = skipWhitespace <* (field & (skipComma & field)*) & end
        print(ParseContext.parse("\"ass\\\"hat\"   ,  dickhead  ,\"\",,bob  ", parser: csv))
    }

    func testGlossa() {
        let quote = match <* "\""
        
    }
    
}
