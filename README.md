# Parsimonious

Parsimonious is a parser combinator library written in Swift. While there are several others now, Parsimonious is one of the oldest, started in early 2019.

Parsimonious used functional programming concepts from the start, but the latest version is the most functional yet, emphasizing composability and immutability.

A Parsimonious parser is a type of the form `Parser<Source: Collection, Output>`, where `Source` is the collection we're parsing, and `Output` is the type of the value the parser returns.

In most cases, `Source` is a `String`, but it can be any `Collection` type. It's entirely possible to parse arrays of integers, for example. (See the unit tests.)

Parser combinators are large topic which I cannot cover here. If you're already familiar with parser combinators, Parsimonious shouldn't be too difficult. The unit tests contain almost all you need to know, including the implementation of a complete JSON parser.
