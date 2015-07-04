//
//  ParseResult.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public enum ParseResult<T>: CustomDebugStringConvertible {
    public typealias Match = (T, String.Index)
    case Matched([Match])
    case NotMatched
    case Error(ErrorType, String.Index)
    
    public var debugDescription: String {
        switch self {
        case .Matched(let matches): return "ParseResult.Matched \(matches)"
        case .NotMatched: return "ParseResult.NotMatched"
        case let .Error(e, p): return "ParseResult.Error \(e) @ \(p)"
        }
    }
}
