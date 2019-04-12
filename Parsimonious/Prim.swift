//
//  Prim.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/10/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func satisfy<C: Collection, E>(type: C.Type = C.self, _ test: @escaping (E) -> Bool) -> Parser<C, E> where E == C.Element {
    return { context in
        if context.atEnd {
            throw ParseError(message: "Unexpected end of input.", context: context)
        }
        let e = context.next!
        if test(e) {
            context.offset(by: 1)
            return e
        } else {
            throw ParseError(message: "Unexpected \(e).", context: context)
        }
    }
}

public func count<C: Collection, T>(from: Int, to: Int, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {    
    assert(from >= 0 && from <= to && to > 0, "Invalid range for count. Valid for from and to are: from >= 0 && from <= to && to > 0.")
    return transact { context in
        var values: [T] = []
        while values.count < from {
            do {
                try values.append(parser(context))
            } catch {
                if from == to {
                    throw ParseError(message: "Expected \(to) but got \(values.count).", context: context, inner: error)
                } else if to == Int.max {
                    throw ParseError(message: "Expected at least \(from) but got \(values.count).", context: context, inner: error)
                } else {
                    throw ParseError(message: "Expected at least \(from) and at most \(to), but got \(values.count).", context: context, inner: error)
                }
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

public func or<C: Collection, T>(_ parsers: [Parser<C, T>]) -> Parser<C, T> {
    assert(parsers.count > 0, "The 'or' combinator requires at least one parser.")
    return { context in
        if (parsers.count == 1) {
            return try parsers[0](context)
        } else {
            var lastError: Error!
            for parser in parsers {
                do {
                    return try parser(context)
                } catch {
                    lastError = error
                }
            }
            // The only way we can get here is if the last parser fails.
            throw lastError
        }
    }
}

public func peek<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T> {
    return { context in
        context.saveIndex()
        defer { context.restoreIndex() }
        return try parser(context)
    }
}

public func lift<C: Collection, I, O>(_ transform: @escaping (I) -> O, _ parser: @escaping Parser<C, I>) -> Parser<C, O> {
    return { context in
        return try transform(parser(context))
    }
}

public func fail<C: Collection, T>(_ message: String) -> Parser<C, T> {
    return { context in
        throw ParseError(message: message, context: context)
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

public func left<C: Collection, L, R>(_ lparser: @escaping Parser<C, L>, _ rparser: @escaping Parser<C, R>) -> Parser<C, L> {
    return transact { context in
        let value = try lparser(context)
        _ = try rparser(context)
        return value
    }
}

public func right<C: Collection, L, R>(_ lparser: @escaping Parser<C, L>, _ rparser: @escaping Parser<C, R>) -> Parser<C, R> {
    return { context in
        _ = try lparser(context)
        return try rparser(context)
    }
}

public func sequence<C: Collection, T>(_ parsers: [Parser<C, T>]) -> Parser<C, [T]> {
    return transact { context in
        return try parsers.map{ parser in try parser(context) }
    }
}

public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T>, _ rparser: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        var values = [try lparser(context)]
        if let value = try rparser(context) {
            values.append(value)
        }
        return values
    }
}

public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T?>, _ rparser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values: [T] = []
        if let value = try lparser(context) {
            values.append(value)
        }
        try values.append(rparser(context))
        return values
    }
}

public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, [T]>, _ rparser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return transact { context in
        var values = try lparser(context)
        try values.append(rparser(context))
        return values
    }
}

public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T>, _ rparser: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return transact { context in
        let value = try lparser(context)
        var values = try rparser(context)
        values.insert(value, at: 0)
        return values
    }
}

public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, [T]>, _ rparser: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return transact { context in
        var values = try lparser(context)
        if let value = try rparser(context) {
            values.append(value)
        }
        return values
    }
}

public func sequence<C: Collection, T>(_ lparser: @escaping Parser<C, T?>, _ rparser: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return transact { context in
        let value = try lparser(context)
        var values = try rparser(context)
        if let value = value {
            values.insert(value, at: 0)
        }
        return values
    }
}


