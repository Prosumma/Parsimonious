//
//  ParsimoniousConditionTests.swift
//  
//
//  Created by Gregory Higley on 12/24/21.
//

import XCTest
import Parsimonious

enum Op {
  case and, or
}

indirect enum Condition {
  case identifier(String)
  case not(Condition)
  case logic(Condition, Op, Condition)
}

let identifier = Condition.identifier <%> many1S(any: istring("abcdefghijkmlnopqrstuvwxyz0123456789"))

func notExpression(_ context: Context<String>) throws -> Condition {
  return try context <- Condition.not <%> (((string("NOT") <* char(\Character.isWhitespace)) | string("!")) *> ows *> simpleExpression)
}

func parensExpression(_ context: Context<String>) throws -> Condition {
  return try context <- char("(") *> manyS(\Character.isWhitespace) *> logicExpression <* manyS(\Character.isWhitespace) <* char(")")
}

func logicExpression(_ context: Context<String>) throws -> Condition {
  let and = Op.and <=> ((char(\Character.isWhitespace) *> string("AND") <* char(\Character.isWhitespace)) | (ows *> string("&") <* ows))
  let or = Op.or <=> ((char(\Character.isWhitespace) *> string("OR") <* char(\Character.isWhitespace)) | (ows *> string("|") <* ows))
  
  var result = try context <- simpleExpression
  while true {
    do {
      let op = try context <- and | or
      let condition2 = try context <- simpleExpression
      result = .logic(result, op, condition2)
    } catch _ as ParsingError {
      return result
    }
  }
  return result
}

let simpleExpression = notExpression | identifier | parensExpression
let expression = manyS(\Character.isWhitespace) *> logicExpression <* manyS(\Character.isWhitespace) <* eof

class ParsimoniousConditionTests: XCTestCase {
  func testCondition() throws {
    let condition = try parse("(a OR b) OR (c AND !(x & y))", with: expression)
    print(condition)
  }
}

