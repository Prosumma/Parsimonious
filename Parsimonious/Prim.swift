//
//  Prim.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func parse<C: Collection, T>(_ contents: C, with parser: Parser<C, T>) throws -> T {
    let context = Context(contents: contents)
    return try parser(context)
}

public func satisfy<C: Collection>(type: C.Type = C.self, _ test: @escaping (C.Element) -> Bool) -> Parser<C, C.Element> {
    return { context in
        if let c = context.rest?.first {
            if test(c) {
                context.offset(by: 1)
                return c
            }
            throw ParseError(message: "Unexpected \(c).", context: context)
        }
        throw ParseError(message: "Unexpected end of input.", context: context)
    }
}

public func optional<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T?> {
    return { context in
        return try? parser(context)
    }
}

public func optional<C: Collection, T>(_ parser: @escaping Parser<C, T>, default defaultValue: T) -> Parser<C, T> {
    return { context in
        return (try? parser(context)) ?? defaultValue
    }
}

public postfix func *?<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, T?> {
    return optional(parser)
}

public func peek<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T> {
    return { context in
        context.saveIndex()
        defer { context.restoreIndex() }
        return try parser(context)
    }
}

public func fail<C: Collection, T>(message: String = "Parsing failed.", type: T.Type = T.self) -> Parser<C, T> {
    return { context in
        throw ParseError(message: message, context: context)
    }
}

public func or<C: Collection, T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<C, T> where Parsers.Element == Parser<C, T> {
    return transact { context in
        var lastError: Error!
        for parser in parsers {
            do {
                return try parser(context)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}

public func or<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, T> {
    return or(parsers)
}

public func |<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T>) -> Parser<C, T> {
    return or(lhs, rhs)
}

public func count<C: Collection, T>(from: Int, to: Int, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        while values.count < from {
            do {
                try values.append(parser(context))
            } catch {
                // TODO: Improve this
                throw ParseError(message: "Expected at least \(from) but got \(values.count).", context: context)
            }
        }
        while values.count < to {
            guard let value = try? parser(context) else {
                break
            }
            values.append(value)
        }
        return values
    }
}

public func count<C: Collection, T>(_ range: Range<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: range.upperBound - 1, parser)
}

public func count<C: Collection, T>(_ range: ClosedRange<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: range.upperBound, parser)
}

public func count<C: Collection, T>(_ range: PartialRangeFrom<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    
}

public func count<C: Collection, T>(_ number: Int, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(number...number, parser)
}

public func many<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        while true {
            do {
                try values.append(parser(context))
            } catch _ as ParseError<C> {
                break
            } catch {
                throw error
            }
        }
        return values
    }
}

public func many<C: Collection, T, S>(_ parser: @escaping Parser<C, T>, sepBy separator: @escaping Parser<C, S>) -> Parser<C, [T]> {
    return many(parser <* separator) & optional(parser)
}

public postfix func *<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return many(parser)
}

public func many1<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        var firstError: ParseError<C>?
        while true {
            do {
                try values.append(parser(context))
            } catch let e as ParseError<C> {
                firstError = e
                break
            } catch {
                throw error
            }
        }
        if values.count == 0 {
            if let firstError = firstError {
                throw firstError
            }
            throw ParseError(message: "Expected at least 1, but got none.", context: context)
        }
        return values
    }
}

public func many1<C: Collection, T, S>(_ parser: @escaping Parser<C, T>, sepBy separator: @escaping Parser<C, S>) -> Parser<C, [T]> {
    return transact { context in
        let values = try context <- many(parser, sepBy: separator)
        if values.count == 0 {
            throw ParseError(message: "Expected at least 1, but got none.", context: context)
        }
        return values
    }
}

public postfix func +<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return many1(parser)
}

public func concat<C: Collection, T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<C, [T]> where Parsers.Element == Parser<C, T> {
    return transact { context in
        var values: [T] = []
        for parser in parsers {
            try values.append(parser(context))
        }
        return values
    }
}

public func concat<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, [T]> {
    return concat(parsers)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, T>, _ rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        return try [lhs(context), rhs(context)].compactMap{ $0 }
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, T?>, _ rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        return try [lhs(context), rhs(context)].compactMap{ $0 }
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, [T]>, _ rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        return try lhs(context) + [rhs(context)]
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, [T]>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, T>, _ rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return transact { context in
        return try [lhs(context)] + rhs(context)
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, [T]>, _ rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        return try lhs(context) + [rhs(context)].compactMap{ $0 }
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, [T]>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, T?>, _ rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return transact { context in
        return try [lhs(context)].compactMap{ $0 } + rhs(context)
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func concat<C: Collection, T>(_ lhs: @escaping Parser<C, T?>, _ rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        return try [lhs(context), rhs(context)].compactMap{ $0 }
    }
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return concat(lhs, rhs)
}

public func onceEachOf<C: Collection, T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<C, [T]> where Parsers.Element == Parser<C, T> {
    return transact { context in
        var parsers = Array(parsers)
        var values: [T] = []
        NEXT: while parsers.count > 0 {
            var lastError: Error!
            for p in 0..<parsers.count {
                let parser = parsers[p]
                do {
                    try values.append(parser(context))
                    _ = parsers.remove(at: p)
                    continue NEXT
                } catch {
                    lastError = error
                }
            }
            throw lastError
        }
        return values
    }
}

public func onceEachOf<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, [T]> {
    return onceEachOf(parsers)
}

public func eachOf<C: Collection, T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<C, [T]> where Parsers.Element == Parser<C, T> {
    return { context in
        var parsers = Array(parsers)
        var values: [T] = []
        NEXT: while parsers.count > 0 {
            for p in 0..<parsers.count {
                let parser = parsers[p]
                do {
                    try values.append(parser(context))
                    _ = parsers.remove(at: p)
                    continue NEXT
                } catch {
                    continue
                }
            }
            break
        }
        return values
    }
}

public func eachOf<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, [T]> {
    return eachOf(parsers)
}

public func eachOneOf<C: Collection, T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<C, [T]> where Parsers.Element == Parser<C, T> {
    return { context in
        let values = try context <- eachOf(parsers)
        if values.count == 0 {
            throw ParseError(message: "Expected at least one, but got none.", context: context)
        }
        return values
    }
}

public func right<C: Collection, T1, T2>(_ lhs: @escaping Parser<C, T1>, _ rhs: @escaping Parser<C, T2>) -> Parser<C, T2> {
    return transact { context in
        try context <- lhs
        return try rhs(context)
    }
}

public func *><C: Collection, T1, T2>(lhs: @escaping Parser<C, T1>, rhs: @escaping Parser<C, T2>) -> Parser<C, T2> {
    return right(lhs, rhs)
}

public func left<C: Collection, T1, T2>(_ lhs: @escaping Parser<C, T1>, _ rhs: @escaping Parser<C, T2>) -> Parser<C, T1> {
    return transact { context in
        let result = try lhs(context)
        try context <- rhs
        return result
    }
}

public func <*<C: Collection, T1, T2>(lhs: @escaping Parser<C, T1>, rhs: @escaping Parser<C, T2>) -> Parser<C, T1> {
    return left(lhs, rhs)
}

public func between<C: Collection, L, T, R>(_ lhs: @escaping Parser<C, L>, _ parser: @escaping Parser<C, T>, _ rhs: @escaping Parser<C, R>) -> Parser<C, T> {
    return lhs *> parser <* rhs
}

public func lift<C: Collection, T1, T2>(_ transform: @escaping (T1) -> T2, _ parser: @escaping Parser<C, T1>) -> Parser<C, T2> {
    return { context in try transform(parser(context)) }
}

public func <*><C: Collection, T1, T2>(transform: @escaping (T1) -> T2, parser: @escaping Parser<C, T1>) -> Parser<C, T2> {
    return lift(transform, parser)
}

public func lift<C: Collection, T1, T2>(_ transform: @escaping (T1) throws -> T2, _ parser: @escaping Parser<C, T1>) -> Parser<C, T2> {
    return { context in try transform(parser(context)) }
}

public func <*><C: Collection, T1, T2>(transform: @escaping (T1) throws -> T2, parser: @escaping Parser<C, T1>) -> Parser<C, T2> {
    return lift(transform, parser)
}

public func <?><C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: String) -> Parser<C, T> {
    return lhs | fail(message: rhs)
}

public func not<C, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, Void> {
    return transact { context in
        if let _ = try? context <- peek(parser) {
            let c = context.rest!.first!
            throw ParseError(message: "Unexpected \(c).", context: context)
        }
        return
    }
}

public func sof<C: Collection>(_ context: Context<C>) throws {
    if context.atStart {
        return
    }
    throw ParseError(message: "Expected start of input.", context: context)
}

public func eof<C: Collection>(_ context: Context<C>) throws {
    if context.atEnd {
        return
    }
    throw ParseError(message: "Unexpected \(context.rest!.first!), expected end of input.", context: context)
}
