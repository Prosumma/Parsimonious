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
