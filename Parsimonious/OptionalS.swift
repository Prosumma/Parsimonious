//
//  OptionalS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func optionalS(_ parser: @escaping ParserS, default defaultValue: @escaping @autoclosure () -> String) -> ParserS {
  optional(parser, default: defaultValue())
}

public func optionalS(_ parser: @escaping ParserS) -> ParserS {
  optional(parser, default: "")
}
