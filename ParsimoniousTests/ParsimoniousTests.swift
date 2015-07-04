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
    
    func testExample() {
        let yes = skipNothing <* match <* "yes" & opt <* (matchOneOf <* "!?." | regex <* "\\d+") *> concat
        let no = skip <* match <* "no"
        let yesOrNo = yes | no
        let grammar = skipWhitespace <* (yesOrNo+ & end) // ! NSError(domain: "Foo", code: 0, userInfo: nil)
        print(ParseContext.parse("yes!  no yes.no yes23   no", parser: grammar))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
