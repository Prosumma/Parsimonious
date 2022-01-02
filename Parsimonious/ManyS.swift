//
//  ManyS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC.
//
//  Licensed under the MIT license: https://opensource.org/licenses/MIT
//  Permission is granted to use, copy, modify, and redistribute the work.
//  Full license information available in the project LICENSE file.
//

import Foundation

public func manyS(_ parser: @escaping ParserS) -> ParserS {
  joined <%> many(parser)
}

public func manyS(_ test: CharacterTest) -> ParserS {
  manyS(char(test))
}

public func manyS(any tests: [CharacterTest]) -> ParserS {
  manyS(char(any: tests))
}

public func manyS(any tests: CharacterTest...) -> ParserS {
  manyS(char(any: tests))
}

public func manyS(all tests: [CharacterTest]) -> ParserS {
  manyS(char(all: tests))
}

public func manyS(all tests: CharacterTest...) -> ParserS {
  manyS(char(all: tests))
}
