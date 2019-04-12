//
//  satisfyChar.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func satisfyChar(_ test: @escaping (Character) -> Bool) -> ParserS {
    return String.init <*> satisfy(test)
}

public func satisfyChar(_ test: CharacterTest) -> ParserS {
    return satisfyChar{ test.testCharacter($0) }
}

public func satisfyChar(any tests: [CharacterTest]) -> ParserS {
    return satisfyChar { c in tests.first(where: { $0.testCharacter(c) }) != nil }
}

public func satisfyChar(any tests: CharacterTest...) -> ParserS {
    return satisfyChar(any: tests)
}

public func satisfyChar(all tests: [CharacterTest]) -> ParserS {
    return satisfyChar { c in tests.allSatisfy{ $0.testCharacter(c) } }
}

public func satisfyChar(all tests: CharacterTest...) -> ParserS {
    return satisfyChar(all: tests)
}

