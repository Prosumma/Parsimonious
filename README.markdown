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

### Reason 2: Strings!

In Swift, a `String` is not merely an array of `Character` instances. It is a much more sophisticated type that handles all the many intricacies of the Unicode standard.

The primitive Parsimonious parsers and combinators don&rsquo;t know anything about strings or characters. They just parse a `Collection` of something or other and either return that something-or-other or an array of it. For example, the `many` combinator matches zero or more instances of a given parser:

```swift
let digits = many("0123456789")
```

Given the string "289", we'll get back an array of `Character` instances: `["2", "8", "9"]`. Because this is often inconvenient, Parsimonious has a suite of parsers and combinators that return strings instead of arrays of characters.

The type of a parser which consumes a `String` and returns the same is `Parser<String, String>`. This type is so common that it has a `typealias`: `ParserS`. In addition to `ParserS`, there is `manyS`, `many1S`, and so on. The `S` suffix indicates that we&rsquo;re dealing with strings, not arrays of characters.

```swift
let digits = manyS("0123456789")
```

The above parser will give us "289" instead of `["2", "8", "9"]`, which is often much more convenient.

### Reason 3: Backtracking

Because Parsimonious is a collection parser rather than a stream parser, backtracking is easy. In fact, _any parser that fails to match **automatically** backtracks_. This makes parsers easier to write and reason about:

```swift
let escape: Character = "\\"
let quote: Character = "\""

let quotation = char(quote) *> manyS(char(all: !escape, !quote) | (char(escape) *> char(any: escape, quote))) <* char(quote)
```

The `quotation` parser matches quoted strings. Quotes themselves can be escaped with a backslash and a backslash must also be escaped with a backslash. Only the text _within_ the quotes is returned as the result of this parser.

If any portion of this parser fails, it will backtrack all the way to the beginning and `throw` a `ParseError`. Whether this `ParseError` terminates parsing depends upon the context in which this parser occurs:

```swift
let quoteOrInteger = quotation | many1S("0123456789") | fail("Expected a quotation or integer")
```

The `|` combinator tries the left-hand parser. If it fails, it swallows the error and tries the right-hand parser. If that fails, then `|` fails and the error propagates up. Since the last failure might not be terribly helpful, we use the `fail` combinator (which always fails) to produce a friendlier error.

### Reason 4: Write Complex Parsers Simply

Let's look again at the type signature of a parser:

```swift
public typealias Parser<C: Collection, T> = (Context<C>) throws -> T
```

Notice the `throws` keyword? This makes Parsimonious "Swifty" and also simplifies the writing of complex parsers. Instead of the constant ceremony of checking return types, we can use a syntax that is more natural to Swift and easier to read:

```swift
func parseDeclaration(_ context: Context<String>) throws -> String {
    return context.transact {
        try context <- string("DECLARE")
        try context <- many1S(\Character.isWhitespace)
        let decl = try context <- many1S(\Character.isLetter)
        try context <- many1S(\Character.isWhitespace)
    }
}
```

The `transact` method is a helper which returns the context's index back to where it started if any of the parsers fails. You should _always_ use this when writing your own parser.

By using `try` instead of some kind of `Result` type, we don't have to continually check the `Result`. This makes parsers easier to write and easier to understand.

Of course, it's much easier to write this particular parser using operators, and you should always do so when possible, as it handles all of these details for you:

```swift
let ws = many1S(\Character.isWhitespace)
let parseDeclaration = string("DECLARE") *> ws *> many1S(\Character.isLetter) <* ws 
```

## Tips &amp; Tricks

### Look At The Unit Tests!

The unit tests implement a fully-functional JSON parser and a pretty good CSV parser. There&rsquo;s a lot to parse in them.

### Not Just Strings!

Parsimonious can parse anything which implements `Collection`. It doesn't have to be a string. This is useful if you want to split the parsing up into phases, where the first phase is simple tokenization. You can use Parsimonious to combine the tokens into larger structures.

### Positions

When tokenizing, it's often useful to know where in the original `Collection` the matched token appeared. The `position` combinator can be used to achieve this.

```swift
enum Token {
    case openParens
    case closeParens
    case sep
    case integer(Int)
}

let openParens = char("(")
let closeParens = char(")")
let sep = char(",")
let integer = many1S("0123456789")

let tokens = [openParens, closeParens, sep, integer].map(position)
let token = or(tokens)
```

Notice how the individual token parsers were defined without `position`, which was added later using higher order functions. This makes the parsers more reusable.

So what do you get when you do this? Instead of returning `Token`, the parsers in the above example now return `Position<String, Token>`, which has useful `startIndex`, `endIndex` and `value` properties.

### Peeking

The `peek` combinator matches a parser without consuming any of the underlying `Collection`. It allows one to look ahead at what's next. A good example of its use is in the CSV parser in the unit tests. Consider the parser which produces a `Decimal`:

```swift
let dec = toDecimal <*> many1S(digits) + char(".") + many1S(digits)
```

This is a perfectly good parser, but there are circumstances in a CSV file in which it can cause a false match. Consider:

```
bob,62.135.157.128,4.9
```

Look at `62.135.157.128`. `62.135` happily parses as a decimal, but the CSV parser has no idea what to do with the remaining `157.128`. It terminates with an error. So we need to teach our parser than in the case of a decimal value, it needs to be followed by the separator, the end of the line or the end of the file:

```swift
func delimited<T>(_ parser: @escaping Parser<String, T>) -> Parser<String, T> {
    return surround(parser, with: ows) <* peek(char(sep) | eol | eofS)
}

let dec = toDecimal <*> delimited(many1S(digits) + char(".") + many1S(digits))
```

The `delimited` combinator returns a parser which says that our passed-in parser is expected to be surrounded by optional white space (`ows`) and followed either by the separator character, the end of the line or the end of the file.

An individual "item" in our CSV file is matched as follows:

```swift
let str = CSValue.string <*> (delimited(quotation) | unquotation)
let item = delimited(dec) | delimited(int) | str
```

With `peek`, the IP address fails to parse as a decimal, so the next possibility, an integer, is tried. It, too, fails, until eventually we get to a parser that succeeds: `unquotation`.

The `peek` combinator is almost always used with the `<*` combinator, which must match its left-hand and right-hand parsers, but discards the value of the right-hand parser.

