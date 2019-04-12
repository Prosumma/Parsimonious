//
//  ManyS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func manyS(_ parser: @escaping ParserS) -> ParserS {
    return joined <*> many(parser)
}

public func manyS(_ test: CharacterTest) -> ParserS {
    return manyS(satisfyChar(test))
}

public func manyS(any tests: [CharacterTest]) -> ParserS {
    return manyS(satisfyChar(any: tests))
}

public func manyS(any tests: CharacterTest...) -> ParserS {
    return manyS(satisfyChar(any: tests))
}

public func manyS(all tests: [CharacterTest]) -> ParserS {
    return manyS(satisfyChar(all: tests))
}

public func manyS(all tests: CharacterTest...) -> ParserS {
    return manyS(satisfyChar(all: tests))
}
