# Parsimonious

Parsimonious is a parser combinator library written in Swift. While there are several others now, Parsimonious is one of the oldest, started in early 2019.

Parsimonious used functional programming concepts from the start, but the latest version is the most functional yet, emphasizing composability and immutability.

A Parsimonious parser is a type of the form `Parser<Source: Collection, Output>`, where `Source` is the collection we're parsing, and `Output` is the type of the value the parser returns.

In most cases, `Source` is a `String`, but it can be any `Collection` type. It's entirely possible to parse arrays of integers, for example. (See the unit tests.)

Parser combinators are large topic which I cannot cover here. If you're already familiar with parser combinators, Parsimonious shouldn't be too difficult. The unit tests contain almost all you need to know, including the implementation of a complete JSON parser.

## Basic Combinators &amp; Operators

The fundamental combinator is `match`, which matches a single element in the underlying collection using a predicate:

```swift
public func match<C: Collection>(_ test: @escaping (C.Element) -> Bool) -> Parser<C, C.Element>
```

All other combinators ultimately build atop this one.

### Strings

When working with strings, `match` can be a bit inconvenient, because it returns a `Character`, and combinators built on it will often return `[Character]`. Most of the time, that's not what we want, so there are specialized combinators for working with `Character` and `String`. These always return a `String`.

```swift
public func char<C: Collection>(
  _ test: @escaping (Character) -> Bool
) -> Parser<C, String> where C.Element == Character {
  match(test).joined()
}
```

This is essentially the same as `match`, but it consumes a `Character` and gives a `String`.

### Operators

What parser combinator library would be worth its salt without operators?

Parsimonious has only a few. 

`postfix operator *`

This operator is exactly the same as the `many` combinator, which matches 0 or more of the underlying parser. For example, to match 0 or more of the character "a":

```swift
match("a")*
```

This will return `[Character]`. Postfix `*` is overloaded to work with combinators which return `Character` or `String`, in which case it always returns `String`:

```swift
char("a")*
```

This will return a `String` containing the matched characters.

`postfix operator +`

This operator is the same as the `many1` combinator, which matches 1 or more of the underlying parser.

```swift
char("a")+
```

The above matches 1 or more "a" characters.

Everything I said about `*` above applies to `+`.

`prefix operator *`

This is the same as the `optional` combinator:

```swift
*char("a")
```

The above returns 0 or 1 "a". The returned value must implement the `Defaultable` protocol. In the event of a failed match, the default value is returned. In this case, that's an empty `String`.

`infix operator <|>`

This is the choice operator:

```swift
string("foo") <|> string("bar")
```

This first attempts to match the string "foo". If that fails, it attempts to match "bar". If that fails, then parsing fails with the error of the last attempted match. The `fail` combinator can be used to customize errors:

```swift
string("foo") <|> string("bar") <|> fail(MyError.oops)
```

`infix operator +`

The built-in `+` operator has been overloaded to join together arrays and strings respectively.

```swift
string("foo")* + string("bar")
```

This matches 0 or more of the string "foo" followed by 1 instance of the string "bar", so it would match "bar", "foobar", "foofoobar", etc.

## Laziness

Wherever possible, combinators which take other parsers as arguments use `@escaping @autoclosure` for this.

This is important in a parser combinator library because combinators are often recursive. Consider the following from the unit tests:

```swift
var jarray: JParser = bracketed(many(json, separator: ",")) >>> JSON.array

let json = whitespacedWithNewlines(jstring <|> jnumber <|> jobject <|> jarray <|> jbool <|> jnull)
```

Notice that `jarray` refers to `json` and _vice versa_. Without laziness, this wouldn't be possible. The Swift compiler would complain.

If you write your own combinators, I highly recommend this practice.

There are a few places where `@escaping @autoclosure` cannot be used, such as variadic parameters. Most of the time, this should not be a problem, but in the rare circumstance when it is, the `deferred` combinator can be used to make any parser lazy:

```swift
let bar = chain(deferred(foo), baz)
let foo = chain(deferred(bar), boo)
```

Since `chain` uses variadic parameters, they cannot be autoclosures. Using `deferred` here allows the two definitions to reference each other. Since `baz` and `boo` presumably don't reference `bar` and `foo`, using `deferred` with them is not necessary.

An overload of `deferred` allows the definition of an `ad hoc`, lazy parser:

```swift
let nothing: Parser<String, Void> = deferred { source, index in
  return .success(State(output: (), range: index..<index>))
}
```

This parser consumes nothing and returns `Void`, but illustrates the point.
