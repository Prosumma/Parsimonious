//
//  ParseError.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-19.
//

public struct ParseError<Source: Collection>: Error {
  public enum Reason: Error {
    case nomatch, eof, outOfBounds, error(Error)
  }

  public let reason: Reason
  public let index: Source.Index

  public init(reason: Reason, index: Source.Index) {
    self.reason = reason
    self.index = index
  }
}

func throwToResult<Source: Collection, T>(
  _ index: Source.Index,
  action: () throws -> T
) -> Result<T, ParseError<Source>> {
  do {
    return try .success(action())
  } catch let e as ParseError<Source> {
    return .failure(e)
  } catch let e as ParseError<Source>.Reason {
    return .failure(.init(reason: e, index: index))
  } catch {
    return .failure(.init(reason: .error(error), index: index))
  }
}
