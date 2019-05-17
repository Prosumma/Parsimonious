## Parsers And Parser Combinators? What?

I can&rsquo;t do justice to this topic here. [Wikipedia](https://en.wikipedia.org/wiki/Parser_combinator) has the canonical article and your favorite search engine will have lots more information. 

For those that already know a bit, a Parsimonious parser is a function with the following type signature:

```swift
public typealias Parser<C: Collection, T> = (Context<C>) throws -> T
```

You&rsquo;ll notice that the type signature includes `Collection`. Parsimonious is not a stream parser. This allows easier backtracking at the expense of not being able to parse extremely large amounts of data. For the vast majority of uses, this will not be a problem.

## Why Parsimonious?

### Reason 1: Character Tests

Parsimonious takes a slightly novel approach to parsing text. Most parser combinator frameworks have built-ins like `whitespace` or `newline`. Instead of this, Parsimonious has the concept of _character tests_.

This is easier to demonstrate than to explain, but it&rsquo;s quite easy to use. Let&rsquo;s match a sequence of at least one character which may not include whitespace or punctuation characters.

```swift
many1S(all: !\Character.isWhitespace, !\Character.isPunctuation)
```

Let&rsquo;s parse this parser for a moment. The `S` suffix tells us that this parser parses a string and returns a string. (More on that later.) The `all:` tells us that all of the tests must return `true` for the parser to match. Inside the parentheses, we have two "negated" keypaths. Using the `!` operator with the keypaths reverses the test implied by the keypath.

So what is a character test? 

- Any `KeyPath<Character, Bool>`
- Any `Character`
- Any `String` (which automatically implies "one of")
- An instance of `ExplicitCharacterTest` 
- Any type which implements the `CharacterTest` protocol

In addition, the `test(any:)` and `test(all:)` functions, which themselves return a character test, can be used to combine tests to dizzying heights:

```swift
char(all: !\Character.isWhitespace, !"07", test(any: \Character.isLetter, \Character.isDigit))
```

The above parser matches a single character, which must not be whitespace and must not be one of "0" or "7". In addition, it must either be a letter or digit. So it will match "9" but not "0". It will match "x" but not " ".

Using this methodology, extremely sophisticated parsers can be created.

### Reason 2: Backtracking

Because Parsimonious is a collection parser rather than a stream parser, backtracking is easy. In fact, _any parser that fails to match *automatically* backtracks_. This makes parsers easier to write and reason about:

```swift
let escape: Character = "\\"
let quote: Character = "\""

let quotation = char(quote) *> manyS(char(all: !escape, !quote) | (char(escape) *> char(any: escape, quote))) <* char(quote)
```

The `quotation` parser matches quoted strings. Quotes themselves can be escaped with a backslash and a backslash must also be escaped with a backslash. Only the text _within_ the quotes is "returned" by the parser.

