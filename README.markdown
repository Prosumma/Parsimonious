## Parsimonious

Parsimonious is a simple parser combinator library written in Swift with the goals of simplicity and Swiftiness.

It differs from traditional parser combinator libraries in a few ways:

#### Swiftiness 

Parsimonious parser combinators are functions with the type signature `(Context) throws -> T`. By using `throws` rather than returning a `Result` type, we gain certain syntactic advantages that will be demonstrated later.

#### Backtracking

Parsimonious parser combinators always backtrack on failure. That is, they consume input only on success. This sacrifices a bit of efficiency in favor of simplicity.

#### Strings Are Fundamental

Swift's `String` type is not merely an array of `Character` instances, and Swift's `Character` type is not as easy to work with as `String` is.

Because of this, the Parsimonious' core library treats `String` as more fundamental than `Character`. For example:

```swift
public func satisfy(_ test: @escaping (Character) -> Bool) -> Parser<String>
```

The classic `satisfy` function found in most parser combinator libraries takes a `Character` as input but returns `Parser<String>`, not `Parser<Character>`.

In addition, Parsimonious has parser primitives and custom operators that are specifically designed to concatenate strings, e.g.,

```swift
let identifier = letter + optionalS(letters | digits)
```

The `+` combinator takes two `Parser<String>` instances and combines the resultant strings. (This is in contrast to the `&` combinator, which returns an array.)

In addition the `S` suffix on `optionalS` indicates that it is a special version of `optional` designed to work with strings. In this case, `optionalS` never returns `nil`, it always returns an empty string if its argument fails to match. There are other `S`-suffixed combinators, like `manyS` and `many1S`.

### Fundamentals

```swift
// An identifier consists of a letter optionally followed by any combination of letters or digits. The + and manyS combinators always produce strings.
let identifier = letter + manyS(letters | digits)

// A higher-order function which creates a combinator that case-insensitively matches a keyword.
func keyword(_ kw: String) -> Parser<String> {
    return caseInsensitiveString(kw) 
}

// A combinator which parses a class definition of the pattern "CLASS name". It returns only the identifier of the class.
let classDeclaration = keyword("class") *> whitespaces *> identifier

let classDeclarations = many1(classDeclaration <* (whitespaces | eofS))

// Returns the array `["foo", "bar", "baz"]`.
let classes = try! parse("CLASS foo CLASS bar CLASS baz", with: classDeclarations <* eof)
```

