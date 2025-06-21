//
//  ParseResult.swift
//  Parsimonious
//
//  Created by Greg Higley on 2023-10-27.
//

public typealias ParseResult<Source: Collection, Output> = Result<ParseState<Source, Output>, ParseError<Source>>

@inlinable
func >>> <Success, NewSuccess, Failure: Error>(
  result: Result<Success, Failure>,
  transform: @Sendable (Success) -> (NewSuccess)
) -> Result<NewSuccess, Failure> {
  result.map(transform)
}

@inlinable
func *>> <Success, NewSuccess, Failure: Error>(
  result: Result<Success, Failure>,
  value: @escaping @Sendable @autoclosure () -> NewSuccess
) -> Result<NewSuccess, Failure> {
  result.map { _ in value() }
}

@usableFromInline
func flatten<Success, Failure: Error>(
  _ result: Result<Result<Success, Failure>, Failure>
) -> Result<Success, Failure> {
  switch result {
  case .success(let result):
    return result
  case .failure(let failure):
    return .failure(failure)
  }
}

@inlinable
func >>= <Success, NewSuccess, Failure: Error>(
  result: Result<Success, Failure>,
  transform: @Sendable (Success) -> Result<NewSuccess, Failure>
) -> Result<NewSuccess, Failure> {
  flatten(result.map(transform))
}
