//
//  Prim.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func parse<T>(string: String, with parser: Parser<T>) throws -> T {
    let context = Context(string: string)
    return try parser(context)
}

public func optional<T>(_ parser: @escaping Parser<T>) -> Parser<T?> {
    return { context in
        return try? parser(context)
    }
}

public func optional<T>(_ parser: @escaping Parser<T>, default defaultValue: T) -> Parser<T> {
    return { context in
        return (try? parser(context)) ?? defaultValue
    }
}

public postfix func *?<T>(parser: @escaping Parser<T>) -> Parser<T?> {
    return optional(parser)
}

public func peek<T>(_ parser: @escaping Parser<T>) -> Parser<T> {
    return { context in
        context.saveIndex()
        defer { context.restoreIndex() }
        return try parser(context)
    }
}

public func fail<T>(message: String = "Parsing failed.", type: T.Type = T.self) -> Parser<T> {
    return { context in
        throw ParseError(message: message, context: context)
    }
}

public func or<T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<T> where Parsers.Element == Parser<T> {
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

public func or<T>(_ parsers: Parser<T>...) -> Parser<T> {
    return or(parsers)
}

public func |<T>(lhs: @escaping Parser<T>, rhs: @escaping Parser<T>) -> Parser<T> {
    return or(lhs, rhs)
}

public func count<T>(_ range: Range<Int>, _ parser: @escaping Parser<T>) -> Parser<[T]> {
    return transact { context in
        var values: [T] = []
        while values.count < range.lowerBound {
            do {
                try values.append(parser(context))
            } catch {
                throw ParseError(message: "Expected \(range.lowerBound) to \(range.upperBound - 1), but got \(values.count).", context: context)
            }
        }
        while values.count < range.upperBound - 1 {
            guard let value = try? parser(context) else {
                break
            }
            values.append(value)
        }
        return values
    }
}

public func count<T>(_ number: Int, _ parser: @escaping Parser<T>) -> Parser<[T]> {
    return transact { context in
        var values: [T] = []
        while values.count < number {
            do {
                try values.append(parser(context))
            } catch {
                throw ParseError(message: "Expected \(number), but got \(values.count).", context: context)
            }
        }
        return values
    }
}

public func many<T>(_ parser: @escaping Parser<T>) -> Parser<[T]> {
    return transact { context in
        var values: [T] = []
        while true {
            do {
                try values.append(parser(context))
            } catch _ as ParseError {
                break
            } catch {
                throw error
            }
        }
        return values
    }
}

public func many<T, S>(_ parser: @escaping Parser<T>, sepBy separator: @escaping Parser<S>) -> Parser<[T]> {
    return many(parser <* separator) & optional(parser)
}

public postfix func *<T>(parser: @escaping Parser<T>) -> Parser<[T]> {
    return many(parser)
}

public func many1<T>(_ parser: @escaping Parser<T>) -> Parser<[T]> {
    return transact { context in
        var values: [T] = []
        var firstError: ParseError?
        while true {
            do {
                try values.append(parser(context))
            } catch let e as ParseError {
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

public func many1<T, S>(_ parser: @escaping Parser<T>, sepBy separator: @escaping Parser<S>) -> Parser<[T]> {
    return transact { context in
        let values = try context <- many(parser, sepBy: separator)
        if values.count == 0 {
            throw ParseError(message: "Expected at least 1, but got none.", context: context)
        }
        return values
    }
}

public postfix func +<T>(parser: @escaping Parser<T>) -> Parser<[T]> {
    return many1(parser)
}

public func concat<T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<[T]> where Parsers.Element == Parser<T> {
    return transact { context in
        var values: [T] = []
        for parser in parsers {
            try values.append(parser(context))
        }
        return values
    }
}

public func concat<T>(_ parsers: Parser<T>...) -> Parser<[T]> {
    return concat(parsers)
}

public func &<T>(lhs: @escaping Parser<T>, rhs: @escaping Parser<T>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<T>, _ rhs: @escaping Parser<T?>) -> Parser<[T]> {
    return transact { context in
        return try [lhs(context), rhs(context)].compactMap{ $0 }
    }
}

public func &<T>(lhs: @escaping Parser<T>, rhs: @escaping Parser<T?>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<T?>, _ rhs: @escaping Parser<T>) -> Parser<[T]> {
    return transact { context in
        return try [lhs(context), rhs(context)].compactMap{ $0 }
    }
}

public func &<T>(lhs: @escaping Parser<T?>, rhs: @escaping Parser<T>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<[T]>, _ rhs: @escaping Parser<T>) -> Parser<[T]> {
    return transact { context in
        return try lhs(context) + [rhs(context)]
    }
}

public func &<T>(lhs: @escaping Parser<[T]>, rhs: @escaping Parser<T>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<T>, _ rhs: @escaping Parser<[T]>) -> Parser<[T]> {
    return transact { context in
        return try [lhs(context)] + rhs(context)
    }
}

public func &<T>(lhs: @escaping Parser<T>, rhs: @escaping Parser<[T]>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<[T]>, _ rhs: @escaping Parser<T?>) -> Parser<[T]> {
    return transact { context in
        return try lhs(context) + [rhs(context)].compactMap{ $0 }
    }
}

public func &<T>(lhs: @escaping Parser<[T]>, rhs: @escaping Parser<T?>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<T?>, _ rhs: @escaping Parser<[T]>) -> Parser<[T]> {
    return transact { context in
        return try [lhs(context)].compactMap{ $0 } + rhs(context)
    }
}

public func &<T>(lhs: @escaping Parser<T?>, rhs: @escaping Parser<[T]>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func concat<T>(_ lhs: @escaping Parser<T?>, _ rhs: @escaping Parser<T?>) -> Parser<[T]> {
    return transact { context in
        return try [lhs(context), rhs(context)].compactMap{ $0 }
    }
}

public func &<T>(lhs: @escaping Parser<T?>, rhs: @escaping Parser<T?>) -> Parser<[T]> {
    return concat(lhs, rhs)
}

public func onceEachOf<T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<[T]> where Parsers.Element == Parser<T> {
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

public func onceEachOf<T>(_ parsers: Parser<T>...) -> Parser<[T]> {
    return onceEachOf(parsers)
}

public func eachOf<T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<[T]> where Parsers.Element == Parser<T> {
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

public func eachOf<T>(_ parsers: Parser<T>...) -> Parser<[T]> {
    return eachOf(parsers)
}

public func eachOneOf<T, Parsers: Sequence>(_ parsers: Parsers) -> Parser<[T]> where Parsers.Element == Parser<T> {
    return { context in
        let values = try context <- eachOf(parsers)
        if values.count == 0 {
            throw ParseError(message: "Expected at least one, but got none.", context: context)
        }
        return values
    }
}

public func right<T1, T2>(_ lhs: @escaping Parser<T1>, _ rhs: @escaping Parser<T2>) -> Parser<T2> {
    return transact { context in
        try context <- lhs
        return try rhs(context)
    }
}

public func *><T1, T2>(lhs: @escaping Parser<T1>, rhs: @escaping Parser<T2>) -> Parser<T2> {
    return right(lhs, rhs)
}

public func left<T1, T2>(_ lhs: @escaping Parser<T1>, _ rhs: @escaping Parser<T2>) -> Parser<T1> {
    return transact { context in
        let result = try lhs(context)
        try context <- rhs
        return result
    }
}

public func <*<T1, T2>(lhs: @escaping Parser<T1>, rhs: @escaping Parser<T2>) -> Parser<T1> {
    return left(lhs, rhs)
}

public func between<L, T, R>(_ lhs: @escaping Parser<L>, _ parser: @escaping Parser<T>, _ rhs: @escaping Parser<R>) -> Parser<T> {
    return lhs *> parser <* rhs
}

public func lift<T1, T2>(_ transform: @escaping (T1) -> T2, _ parser: @escaping Parser<T1>) -> Parser<T2> {
    return { context in try transform(parser(context)) }
}

public func <*><T1, T2>(transform: @escaping (T1) -> T2, parser: @escaping Parser<T1>) -> Parser<T2> {
    return lift(transform, parser)
}

public func lift<T1, T2>(_ transform: @escaping (T1) throws -> T2, _ parser: @escaping Parser<T1>) -> Parser<T2> {
    return { context in try transform(parser(context)) }
}

public func <*><T1, T2>(transform: @escaping (T1) throws -> T2, parser: @escaping Parser<T1>) -> Parser<T2> {
    return lift(transform, parser)
}

public func ifError<T>(_ parser: @escaping Parser<T>, error: String) -> Parser<T> {
    return transact { context in
        do {
            return try context <- parser
        } catch _ {
            throw ParseError(message: error, context: context)
        }
    }
}

public func <?><T>(lhs: @escaping Parser<T>, rhs: String) -> Parser<T> {
    return ifError(lhs, error: rhs)
}


public func sof(_ context: Context) throws {
    if context.atStart {
        return
    }
    throw ParseError(message: "Expected start of input.", context: context)
}

public func eof(_ context: Context) throws {
    if context.atEnd {
        return
    }
    throw ParseError(message: "Unexpected \(context.substring!.first!), expected end of input.", context: context)
}
