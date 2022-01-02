//
//  OptionalS.swift
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

public func optionalS(
  _ parser: @escaping ParserS,
  default defaultValue: @escaping @autoclosure () -> String
) -> ParserS {
  optional(parser, default: defaultValue())
}

public func optionalS(_ parser: @escaping ParserS) -> ParserS {
  optional(parser, default: "")
}
