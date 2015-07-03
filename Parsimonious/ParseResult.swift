//
//  ParseResult.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public enum ParseResult<T> {
    case Matched([T])
    case NotMatched
    case Error(ErrorType)
}
