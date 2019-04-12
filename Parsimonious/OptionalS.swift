//
//  OptionalS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func optionalS(_ parser: @escaping ParserS, default defaultValue: String = "") -> ParserS {
    return optional(parser, default: defaultValue)
}
