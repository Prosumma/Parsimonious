# Parsimonious

Parsimonious is a small parser-combinator library for Swift. You build big parsers out of small ones, then run them over any in-memory `Collection`, most often a `String`.

It's meant for the parsing most programs actually need: small languages, configuration formats, query syntaxes, and tokens. It tries to be small and pleasant to use, and backtracking is automatic. It isn't a streaming parser. The whole input lives in memory, which is what makes backtracking cheap.

Parsimonious has been around since 2019. Version 3 is a rewrite for Swift 6: parsers are `Sendable`, and errors use typed throws.

## Installation

Parsimonious requires Swift 6.4 and macOS 13 or later. Add it to your `Package.swift`:

```swift
.package(url: "https://github.com/Prosumma/parsimonious.git", from: "3.0.0")
```

Then add `.product(name: "Parsimonious", package: "parsimonious")` to your target's dependencies.

## A first parser

This parser reads a bracketed list of integers, such as `[1, 2, 3]`:

```swift
import Parsimonious

struct IntegerOverflow: Error {}

let digits = char(anyOf: "0123456789")+.toString()
let integer = digits.map { text in
  guard let n = Int(text) else { throw IntegerOverflow() }
  return n
}
let comma = char(",").whitespaced()
let list = integer.many(separatedBy: comma).whitespaced().bracketed()

let numbers = try parse("[1, 2, 3]", with: list.end())   // [1, 2, 3]
```

Reading from the top:

- `char(anyOf:)` matches one digit. The postfix `+` repeats it one or more times, and `toString()` turns the resulting `[Character]` into a `String`.
- `map` turns the text into an `Int`. If the transform throws, the parser fails.
- `char(",").whitespaced()` matches a comma with optional whitespace on either side.
- `many(separatedBy:)` matches zero or more integers separated by commas. `whitespaced()` allows space just inside the brackets, and `bracketed()` requires the `[` and `]`.
- `end()` requires that nothing is left over. Without it, `parse` stops wherever the parser stops and ignores the rest of the input.

## Parsers

A parser has the type `Parser<Input, Output>`. `Input` is the collection being parsed, and `Output` is the type of value the parser produces. `list` above is a `Parser<String, [Int]>`.

A parser receives an `Input.SubSequence` (a `Substring` when parsing a `String`). It either returns a `ParseOutput`, which holds its output and the rest of the input, or throws a `ParseError<Input>`.

There are two ways to run a parser:

```swift
let numbers = try parse("[1, 2] rest", with: list)   // [1, 2]

let result = try list.parse("[1, 2] rest")
result.output   // [1, 2]
result.input    // " rest"
```

Neither one requires the parser to consume all of its input. That's what `end()` is for.

Combinators accept anything that conforms to the `Parsing` protocol and return a `Parser`. The exception is `tuple`, which takes `Parser` values. Since every combinator returns one, that only matters for your own `Parsing` types, which `eraseToParser()` converts.

## Matching characters

| Parser | Matches |
|---|---|
| `char("a")` | The character `a` |
| `char("a", matching: .simple)` | `a` or `A` |
| `char(anyOf: "+-")` | Any one of `+` and `-` |
| `char(not: "'")` | Any character except `'` |
| `char(\.isLetter)` | Any character whose property is `true` |
| `char(not: \.isWhitespace)` | Any character whose property is `false` |
| `string("let")` | The text `let` |
| `string("straße", matching: .folded)` | `straße`, `STRASSE`, `Strasse` and so on |
| `keyword(Keyword.self)` | The raw value of any case of a `String`-backed `CaseIterable` enum, outputting the case |
| `scalar("\"")` | The Unicode scalar `"`, even if a combining mark follows it |
| `scalar(anyOf: "+-")`, `scalar(not: "\"")` | Any one of the scalars, or any scalar except one |
| `scalar(\.properties.isDiacritic)` | Any scalar whose property is `true` (`scalar(not:)` for `false`) |
| `scalar(where: { $0.isASCII })` | Any scalar that passes a test |
| `Parsers.whitespace` | One whitespace character, all of whose scalars are whitespace |
| `Parsers.end` | The end of the input, without consuming anything |
| `just(42)` | Nothing; always succeeds with `42` |

The `char` parsers output the `Character` they matched, and `string` outputs the matched text as it appears in the input, which differs from the pattern when case is ignored. `CaseMatching` controls how case is compared:

- `.exact`, the default: characters must be identical.
- `.simple`: case is ignored one character at a time, so `a` matches `A`, but `ß` doesn't match `ss`. This doesn't depend on the locale, so the dotless `ı` stays distinct from `I`.
- `.folded`: full Unicode case folding, so `ß` matches `ss`. The matched text can be a different length from the pattern.

`keyword` saves writing an `or` of `string`s by hand:

```swift
enum Keyword: String, CaseIterable, Sendable {
  case `in`, int, `let`
}

let kw = keyword(Keyword.self)
// "int" → .int, "in x" → .in, "var" fails with `Expected one of "in", "int", "let".`
```

It tries longer raw values first, so `int` isn't mistaken for `in`, and it takes `matching:` like `string` does. It doesn't check what follows a match, so `integer` matches `int`. Add a boundary where your grammar needs one: `keyword(Keyword.self) <* char(\.isLetter).not()`.

For elements that aren't characters, `satisfy { … }` matches one element that passes a test, and `eq(x)` matches one element equal to `x`.

### Characters and scalars

A Swift `Character` is what a reader sees as one character, which can be several Unicode scalars: `é` can be written as a single scalar or as `e` followed by a combining accent. That's the right unit for human text, and it's what `char` and `string` match. Two spellings of the same character are equal, and `char("a")` doesn't match the `a` at the start of a decomposed `á`.

But a combining mark joins whatever comes before it, punctuation included. A `"` followed by U+0301 is a single `Character`, so `char("\"")` can't match it. Grammars defined on scalars, such as JSON, need to match the `"` and leave the mark for whatever comes next. The `scalar` parsers do that. Each consumes exactly one scalar from a `String` or `Substring` and outputs a `Unicode.Scalar`:

```swift
let quote = scalar("\"")
let result = try quote.parse("\"\u{301}abc\"")
result.input    // "\u{301}abc\"", where the accent is now a character of its own
```

They mix freely with `char` and `string`, which treat whatever follows a scalar as a new character. `toString()` works on their output as it does for characters. Unlike `Character`s, scalars aren't compared by canonical equivalence, so `scalar("é")` doesn't match `e` followed by U+0301. Normalize the input first if that matters.

You rarely need to call `scalar` for punctuation, because the delimiter helpers already use it. With `String` or `Substring` input, `delimited(by: "|")`, `bracketed()`, `doubleStraightQuoted()` and the rest match their delimiters as scalars, so `doubleStraightQuoted()` handles a string that starts with a combining mark.

Whitespace goes the other way. `Parsers.whitespace`, and so `whitespaced()`, only matches a character whose scalars are all whitespace. Unicode writes a diacritic on its own as a space followed by the mark, and `Character.isWhitespace` looks only at the first scalar, so `char(\.isWhitespace)` would consume the mark along with the space. `Parsers.whitespace` leaves it for the next parser. `"\r\n"` is still whitespace, since both of its scalars are.

### Type inference

`char`, `string`, `keyword` and `scalar` assume a `String` input when nothing else says otherwise, so `let a = char("a")` is a `Parser<String, Character>`. Other parsers infer their input type from context, which is usually already there. When it isn't, add a type annotation:

```swift
let ws: Parser<String, Character> = Parsers.whitespace
```

## Combining parsers

### Sequencing

| Combinator | Result |
|---|---|
| `a *> b` | Runs `a`, then `b`, and keeps `b`'s output |
| `a <* b` | Runs `a`, then `b`, and keeps `a`'s output |
| `tuple(a, b, c)` | Runs them in order and keeps every output, as a typed tuple |
| `chain(a, b, c)` | Runs parsers with the same output type in order, and collects an array |
| `join(a, b)` | Runs parsers that output arrays in order, and concatenates the arrays |
| `p.followed(by: q)`, `p.preceded(by: q)` | The same as `p <* q` and `q *> p` |
| `p.delimited(by: q)`, `p.delimited(by: q, and: r)` | `p` between `q` and `q`, or between `q` and `r` |
| `p.parenthesized()`, `p.bracketed()`, `p.braced()` | `p` inside `()`, `[]` or `{}` |
| `p.whitespaced()`, `p.whitespaced1()` | `p` with optional, or required, whitespace on both sides |

For example, `tuple(string("let"), char(" ")+, char(\.isLetter))` on `"let x"` outputs `("let", [" "], "x")`, typed `(String, [Character], Character)`.

With `String` or `Substring` input, `followed(by:)`, `preceded(by:)` and `delimited(by:)` also accept a single Unicode scalar directly, as in `p.followed(by: ";")`. `parenthesized()`, `bracketed()`, `braced()`, `singleStraightQuoted()` and `doubleStraightQuoted()` are built on them, so they also need `String` or `Substring` input. Delimiters are matched as scalars; see [Characters and scalars](#characters-and-scalars).

### Alternatives

`a <|> b`, or `or(a, b, c)` for several, tries each parser in turn and returns the first success. Every alternative starts from the same place, however much input the previous ones consumed. See [Backtracking and commitment](#backtracking-and-commitment).

### Repetition

| Combinator | Matches |
|---|---|
| `p*` or `p.many()` | Zero or more |
| `p+` or `p.many1()` | One or more |
| `p.many(separatedBy: s)` | Zero or more, separated by `s` |
| `p.many1(separatedBy: s)` | One or more, separated by `s` |
| `p.count(4)` | Exactly four, failing if any of them fails |
| `p.count(upTo: 4)` | Zero to four |
| `p.optional()` | Zero or one, as an array |

A repetition stops at the first failure, unless that failure is committed, and keeps everything it matched up to that point. It also stops if `p` succeeds without consuming anything, so it can't loop forever. The exception is `count(_:)`, which always runs exactly as many times as you ask, since it can't loop forever anyway.

`optional()` outputs an array rather than an `Optional`, because an optional part is almost always joined to something larger. For example, this matches an integer with an optional sign:

```swift
let signed = join(char(anyOf: "+-").optional(), char(\.isNumber)+).toString()
// "-42" → "-42", "42" → "42"
```

### Lookahead

| Combinator | Result |
|---|---|
| `p.peek()` | Outputs what `p` would, without consuming anything |
| `p.not()` | Succeeds without consuming anything where `p` fails, and fails where `p` succeeds |

`peek` lets you look ahead before choosing a parser. Here `object` and `array` stand for parsers of your own, with the same output type:

```swift
let value = char(anyOf: "{[").peek().flatMap { $0 == "{" ? object : array }
```

`not` is how you keep a keyword from matching the start of a longer word:

```swift
let ifKeyword = string("if") <* char(\.isLetter).not()
// Matches "if" in "if x", but not in "iffy".
```

If `p` fails with a committed error, `not()` rethrows it instead of succeeding. A committed error means the input can't be anything else, so `object.not()` on a malformed object reports the malformed object rather than treating it as "not an object". To treat every failure as "not matched", write `p.uncommit().not()`. When `p` succeeds, the error `not()` throws has no message, so add one with `expecting`.

### Transforming

| Combinator | Result |
|---|---|
| `p.map { … }` | Transforms the output. The transform may throw, which fails the parser. |
| `p.toString()` | Turns a `Character` or `[Character]` output into a `String` |
| `p.array()` | Wraps the output in a one-element array |
| `flatten(p)` | Flattens an array of arrays |
| `p.captured()` | Pairs the output with the input that `p` consumed |
| `p.flatMap { … }` | Chooses the next parser based on `p`'s output. See [Writing your own parsers](#writing-your-own-parsers). |

### Operator precedence

The postfix `*` and `+` bind most tightly, then `*>` and `<*`, then `<|>`. All of them are left-associative. So this:

```swift
char("-") *> char(\.isNumber) <|> char("x")
```

means `(char("-") *> char(\.isNumber)) <|> char("x")`: it matches `-7`, outputting `7`, or `x`.

## Backtracking and commitment

When an alternative fails, `<|>` tries the next one from where the first one started, however much input it consumed. Repetitions do the same with their last attempt. There's no equivalent of Parsec's `try`: backtracking is always on.

The cost is error reporting. A failed alternative might have failed for an interesting reason, but `<|>` can't know that, so it drops the error and moves on. If every alternative fails, all you get is `No alternative matched.`, reported where the `<|>` started:

```swift
let integers = list <|> integer.array()

try parse("[1, 2", with: integers.end())
// Fails with "No alternative matched." at offset 0.
```

The fix is to **commit**. Once you've seen `[`, the input has to be a list, and there's no point trying anything else. A committed error isn't backtracked: `<|>` and repetitions rethrow it immediately.

```swift
let committedIntegers = list.commit1() <|> integer.array()

try parse("[1, 2", with: committedIntegers.end())
// Fails with `Expected "]".` at offset 5.
```

| Combinator | Commits |
|---|---|
| `p.commit1()` | Once `p` has consumed at least one element. This is usually the one you want. |
| `p.commit(after: n)` | Once `p` has consumed at least `n` elements |
| `p.commit()` | Always, even when `p` fails without consuming anything |
| `p.uncommit()` | Never: it undoes any commitment inside `p` |

When these are nested, the outermost one wins.

Commit only where the grammar really has no other option. A committed failure inside `p*` fails the whole repetition, because that's what committed means.

## Errors

`ParseError<Input>` has these properties:

- `reason`: `.nomatch`, or `.eof` if the parser ran out of input.
- `slice`: the input the failing parser consumed before it failed. Its `startIndex` is where that parser started, and its `endIndex` is how far it got. It's empty if the parser failed on its first element.
- `message`: a description such as `Expected "]".`, if there is one.
- `committed`: whether the error is committed.
- `error`: the underlying error, when a `map` transform threw.

The failing parser stopped at `slice.endIndex`. When the input's elements are characters, `location(in:)` turns that into a 1-based line and column:

```swift
func check(_ input: String) {
  do {
    _ = try parse(input, with: committedIntegers.end())
  } catch {
    let (line, column) = error.location(in: input)
    print("Line \(line), column \(column): \(error.message ?? "Parse error.")")
  }
}

check("[1,\n 2")   // Line 2, column 3: Expected "]".
```

Pass the same input you parsed, since the error's indices refer to it.

### Custom messages

`expecting` replaces the message of an error that isn't committed, which is typically the generic one from a failed `<|>`:

```swift
let described = committedIntegers.expecting("Expected a list or an integer.")

// "x" fails with "Expected a list or an integer."
// "[1, 2" still fails with `Expected "]".`
```

A committed error keeps its own message, because it's already more specific than the one you're adding. That includes a token that consumed part of the input: `string("blah").expecting("Expected blah.")` on `"blab"` keeps `Expected "blah".` To change an error in any other way, use `mapError`:

```swift
p.mapError { error in error.message = "Something else." }
p.mapError { input, error in … }   // `input` is what `p` was given.
```

`error.consumed(relativeTo: input)` tells you whether the failing parser got past the start of `input`. Together with `committed`, it's what `commit1()` and `expecting` use, and it's useful when you write your own error-handling combinators.

### Failing `map` transforms

A transform that throws fails its parser like any other failure, so an enclosing `<|>` or repetition can backtrack past it. In `list` above, an integer too large for `Int` makes `many(separatedBy:)` stop, and you get `Expected "]".` instead of the overflow. To keep the transform's error, commit to it:

```swift
let strictInteger = digits.map { text in
  guard let n = Int(text) else { throw IntegerOverflow() }
  return n
}.commit1()
```

The transform's failure is committed because the digits were already consumed, while a parse that fails on its first character is still free to backtrack. The thrown `IntegerOverflow` is in the error's `error` property.

## Recursion

Most languages are recursive: a list can contain lists. Parsimonious has no special combinator for this, because Swift's lazily initialized globals already provide what's needed:

```swift
indirect enum Value: Equatable, Sendable {
  case number(Int)
  case list([Value])
}

let number = integer.map { Value.number($0) }
let nested = value.many(separatedBy: comma).whitespaced().bracketed().commit1().map { Value.list($0) }
let alternatives = number <|> nested

let value: Parser<String, Value> = Parser { input throws(ParseError<String>) in
  try alternatives.parse(input)
}

try parse("[1, [2, 3], []]", with: value.end())
// .list([.number(1), .list([.number(2), .number(3)]), .list([])])
```

`nested` refers to `value`, which is defined after it and refers back to it through `alternatives`. This works because building `value` only creates a closure. The closure doesn't look at `alternatives` until a parse actually runs, and by then every parser can be initialized.

Three rules make it work:

1. **Give the recursive parser an explicit type.** Without `: Parser<String, Value>`, the compiler reports "circular reference", because it can't infer the types of `value` and `nested` from each other.
2. **Define the grammar as global `let`s, or as `static let`s on a type.** Both are initialized lazily, on first use. Local variables inside a function aren't, and the compiler rejects the forward reference ("use of local variable 'value' before its declaration"). Top-level code in `main.swift` or a script isn't lazy either: there, the grammar compiles but crashes at run time.
3. **Keep the alternatives in their own `let`,** as `alternatives` is above. The closure runs on every recursive call, and writing `try (number <|> nested).parse(input)` inside it would rebuild the `<|>` each time.

To keep names like `number` out of the global namespace, use an enum:

```swift
enum Grammar {
  static let number = integer.map { Value.number($0) }
  static let list = value.many(separatedBy: comma).whitespaced().bracketed().commit1().map { Value.list($0) }
  static let alternatives = number <|> list
  static let value: Parser<String, Value> = Parser { input throws(ParseError<String>) in
    try alternatives.parse(input)
  }
}
```

A global function works as the recursion point too, as in `let value = Parser(parse: parseValue)`, and doesn't need the type annotation.

## Writing your own parsers

When the combinators don't fit, write a parser directly:

```swift
/// Takes exactly `n` characters, whatever they are.
func take(_ n: Int) -> Parser<String, String> {
  Parser { input throws(ParseError<String>) in
    guard let end = input.index(input.startIndex, offsetBy: n, limitedBy: input.endIndex) else {
      throw ParseError(reason: .eof, slice: input, message: "Expected \(n) characters.")
    }
    return ParseOutput(input: input[end...], output: String(input[..<end]))
  }
}
```

`take` pairs naturally with `flatMap`, which lets one parser's output decide what to parse next. A netstring such as `3:a:b,` starts with its own length, and the content may contain `:` or `,`:

```swift
let netstring = (integer <* char(":")).flatMap { n in take(n) } <* char(",")

try parse("3:a:b,", with: netstring)   // "a:b"
```

A second `flatMap` overload takes the whole `ParseOutput`, so it can see the rest of the input and throw its own errors.

A few rules for hand-written parsers:

- **Spell out `throws(ParseError<…>)` on the closure.** Swift doesn't yet infer typed throws for closures, and without it you'll get "invalid conversion of thrown error type 'any Error'".
- **Make `slice` what you consumed before failing.** If you fail on the first element, use the empty `input[..<input.startIndex]`. `commit1()`, `expecting` and error positions all depend on it.
- **Use `.eof` when you run out of input,** and `.nomatch` otherwise.
- **Keep parsers immutable once they're built.** Parsers are `Sendable` so they can be shared across isolation boundaries, and one parser may be running in several tasks at once. Swift 6 already rejects the usual ways of capturing mutable state in a parser's closure.

## Parsing other collections

Any `Collection` can be parsed. A common pattern is to turn a `String` into tokens with one grammar, then parse the tokens with another:

```swift
enum Token: Equatable, Sendable {
  case number(Int)
  case plus
}

let operand = Parser<[Token], Int> { input throws(ParseError<[Token]>) in
  guard case .number(let n)? = input.first else {
    let reason: ParseError<[Token]>.Reason = input.isEmpty ? .eof : .nomatch
    throw ParseError(reason: reason, slice: input[..<input.startIndex], message: "Expected a number.")
  }
  return ParseOutput(input: input.dropFirst(), output: n)
}

let sum = tuple(operand, (eq(Token.plus) *> operand)*).map { first, rest in
  rest.reduce(first, +)
}

try parse([.number(1), .plus, .number(2), .plus, .number(3)], with: sum.end())   // 6
```

## License

Parsimonious is available under the MIT license. See [LICENSE](LICENSE).
