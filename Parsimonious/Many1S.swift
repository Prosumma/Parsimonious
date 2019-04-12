//
//  Many1S.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func many1S(_ parser: @escaping ParserS) -> ParserS {
    return joined <*> many1(parser)
}

public func many1S(_ test: CharacterTest) -> ParserS {
    return many1S(char(test))
}

public func many1S(any tests: [CharacterTest]) -> ParserS {
    return many1S(char(any: tests))
}

public func many1S(any tests: CharacterTest...) -> ParserS {
    return many1S(char(any: tests))
}

public func many1S(all tests: [CharacterTest]) -> ParserS {
    return many1S(char(all: tests))
}

public func many1S(all tests: CharacterTest...) -> ParserS {
    return many1S(char(all: tests))
}
