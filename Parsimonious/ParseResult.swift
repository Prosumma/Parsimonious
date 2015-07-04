//
//  ParseResult.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public enum ParseResult<T> {
    public typealias Match = (T, String.Index)
    case Matched([Match])
    case NotMatched
    case Error(ErrorType, String.Index)
}
