//
//  Char.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func char(_ test: @escaping (Character) -> Bool) -> ParserS {
    return String.init <%> satisfy(test)
}

public func char(_ test: CharacterTest) -> ParserS {
    return char{ test.testCharacter($0) }
}

public func char(any tests: [CharacterTest]) -> ParserS {
    return char { c in tests.first(where: { $0.testCharacter(c) }) != nil }
}

public func char(any tests: CharacterTest...) -> ParserS {
    return char(any: tests)
}

public func char(all tests: [CharacterTest]) -> ParserS {
    return char { c in tests.allSatisfy{ $0.testCharacter(c) } }
}

public func char(all tests: CharacterTest...) -> ParserS {
    return char(all: tests)
}

