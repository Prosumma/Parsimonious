//
//  Char.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

// swiftlint:disable identifier_name

import Foundation

/**
 This parser succeeds if `test` succeeds.
 */
public func char(_ test: @escaping (Character) -> Bool) -> ParserS {
  String.init <%> satisfy(test)
}

public func char(_ test: CharacterTest) -> ParserS {
  char(test.testCharacter)
}

public func char(any tests: [CharacterTest]) -> ParserS {
  char { c in tests.first(where: { $0.testCharacter(c) }) != nil }
}

public func char(any tests: CharacterTest...) -> ParserS {
  char(any: tests)
}

public func char(all tests: [CharacterTest]) -> ParserS {
  char { c in tests.allSatisfy { $0.testCharacter(c) } }
}

public func char(all tests: CharacterTest...) -> ParserS {
  char(all: tests)
}
