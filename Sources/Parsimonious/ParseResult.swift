//
//  ParseResult.swift
//  Parsimonious
//
//  Created by Greg Higley on 2023-10-27.
//

public typealias ParseResult<Source: Collection, Output> = Result<ParseState<Source, Output>, ParseError<Source>>

func >>> <Success, NewSuccess, Failure: Error>(
  result: Result<Success, Failure>,
  transform: (Success) -> (NewSuccess)
) -> Result<NewSuccess, Failure> {
  result.map(transform)
}

func *>> <Success, NewSuccess, Failure: Error>(
  result: Result<Success, Failure>,
  value: @escaping @autoclosure () -> NewSuccess
) -> Result<NewSuccess, Failure> {
  result.map { _ in value() }
}

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

func >>= <Success, NewSuccess, Failure: Error>(
  result: Result<Success, Failure>,
  transform: (Success) -> Result<NewSuccess, Failure>
) -> Result<NewSuccess, Failure> {
  flatten(result.map(transform))
}
