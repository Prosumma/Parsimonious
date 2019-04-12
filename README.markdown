## Parsimonious

Parsimonious is a simple parser combinator library written in Swift with the goals of simplicity and Swiftiness.

It differs from traditional parser combinator libraries in a few ways:

#### Swiftiness 

The fundamental type of a Parsimonious `Parser` is:

```swift
typealias Parser<C: Collection, T> = (Context<C>) throws -> T
```

There are two things to note here. First, instead of returning some `Result` type, Parsimonious uses `throw`. As you&rsquo;ll see, this makes parsers _much_ easier and more natural to write, particularly in a language like Swift which lacks monads. 

#### Backtracking

Parsimonious parsers always backtrack on failure. That is, they consume input only on success. This sacrifices a bit of efficiency in favor of simplicity. This is because Parsimonious is a _collection_-parser, not a stream parser. 

#### Strings

Parsimonious can parse any `Collection`, but by far the most commonly parsed `Collection` is `String`. Because of this, Parsimonious has special parsers and combinators for parsing strings built on top of the string parser, `ParserS`:

```swift
typealias ParserS = Parser<String, String>
```

In languages like Haskell, a `String` is simply an array of `Char` instances. In Swift, a `String` is a _collection_ of `Character` instances, but it is not an array. Because of this, many parsers that you might expect would return an array of characters instead automatically concatenate these into a `String`. Where these parsers are variants of existing type-agnostic "primitive" parsers, they bear the suffix `S`, e.g.,

```swift
func manyS(_ parser: @escaping ParserS) -> ParserS
```

This matches a single character, but for convenience returns a `String`. (If you really want a `Character` instead, you can use the lower-level `satisfy` combinator.)

Parsimonious overloads the `+` operator to combine `ParserS` instances, concatenating the result rather than returning an array. For example, here we construct a parser that parses a name. The rule is that the name must not start with a number. 

```swift
let name: ParserS = char(\Character.isLetter) + manyS(any: \Character.isLetter, \Character.isNumber)
```

This will match `xabc1` but not `1cbax`.

#### Character Tests 

Parsimonious introduces the concept of _character tests_ for `ParserS` parsers. A character test is a simple declarative test that can be used in overloads of many `ParserS` combinators to test the properties of characters.

```swift
let whitespaceButNotNewline = char(all: \Character.isWhitespace, !\Character.isNewline)
```

In Parsimonious, every `KeyPath<Character, Bool>` is automatically a character test. This means we can use the properties added to the `Character` type in Swift 5. A `Character` itself is also automatically a character test, as is a `String`. Character tests can be negated using the `!` operator. Here are some more examples:

```swift
// Match a contiguous series of at least one letter, excepting q and Q 
let lettersExceptQ = many1S(all: \Character.isLetter, !"qQ")

// Match a contiguous series of at least one letter or number, but not q, Q, and 7
let lettersAndNumbersExceptQAnd7 = many1S(all: test(any: \Character.isLetter, \Character.isNumber), !"qQ7")
```

The second example makes use of the `test(any:)` function, which can be used to combine `CharacterTest` instances into a single test.

Using `!`, `test(any:)`, `test(all:)`, `char(any:)`, `char(all:)`, `manyS(all:)`, extremely sophisticated parsers can be created. This is why Parsimonious lacks built-in parsers such as `newline` or `whitespace` found in other frameworks. Just build your own!