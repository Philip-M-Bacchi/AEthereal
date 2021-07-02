# AEthereal

## AppleScript-compatible AppleEvents for Swift

AEthereal constructs, sends, and receives replies from AppleScript-compatible AppleEvents. "AppleScript-compatible" means that the entire standard AppleEvent Object Model (object and insertion specifiers, etc.) is available and supported.

## Use

### 4-byte AppleEvent codes

AEthereal refers to 4-byte AppleEvent codes as "AE4 codes", with Swift type `AE4`. 

### Descriptor encoding/decoding

Converion between Swift objects and AppleEvent descriptors is done through the Swift `Codable` interface. Anything `Codable` can be sent in an AppleEvent and decoded from a reply. "Unkeyed containers" encode list descriptors; "keyed containers" encode record descriptors. To use custom record keys, use a `CodingKeys` enum with `AE4` raw type, and conform it to `AE4CodingKey`.

```swift
private enum CodingKeys: AE4, AE4CodingKey {
    // ...
    case container = 0x66726f6d
    // ...
}
```

Keys that are well-known event attribute codes are encoded as such.

To enforce use of a non-default descriptor type code, conform your type to `AETyped`.

```swift
struct ObjectSpecifier: AETyped {
    // ...
    public var aeType: AE4.AEType {
        .objectSpecifier
    }
    // ...
}
```

AppleEvent send functions will encode attributes and parameters for you, but if you still want to manually encode something, use `AEEncoder`. AppleEvent send functions do not decode anything other than errors, so if you have to read the reply data, use `AEDecoder`.

### Query building

Beginning at a `RootSpecifier`, chain calls to any of these methods to build queries:

- `byProperty(_:)` — property object specifier
- `byUserProperty(_:)` — AppleScript "user property" object specifier
- `byIndex(_:_:)` — by-index object specifier
- `byAbsolute(_:_:)` — absolute position (first, last, middle, random) object specifier
- `byRelative(_:_:)` — relative position (before/previous, after/next) object specifier
- `byName(_:_:)` — by-name object specifier
- `byID(_:_:)` — by-ID object specifier
- `byRange(_:_:)` — by-range object specifier
- `byTest(_:_:)` — by-test (filter) object specifier
- `insertion(at:)` — insertion specifier

```swift
let nameOfEveryDocument =
    RootSpecifier.application
    .byAbsolute(AE4.AEType(rawValue: AE4.Classes.document), .all)
    .byProperty(AE4.AEType(rawValue: AE4.Properties.name))
```

### AppleEvent sending

Create an `App` from an `AETarget` and call `sendAppleEvent` with a event class/ID pair and any of:

- a target `Query`
- event parameters (dictionary from `AE4` to anything `Encodable`)
- requested data type (encoded as a parameter)
- "considering/ignoring" flags
- send options and timeout in seconds

If you need a transaction, use  `withTransaction`.

## Origin

Parts of AEthereal come from from the "dynamic bridge" portion of hhas' SwiftAutomation framework.

## License

hhas has released SwiftAutomation into the public domain. AEthereal uses a dual-licensing approach to retain the spirit of "public domain" while dealing with its often dubious legality.

You may choose one of the following license options:

1. AEthereal is released into the public domain, with absolutely no warranty provided.
2. AEthereal is released under the terms of the MIT License, a copy of which is provided in [LICENSE.txt](LICENSE.txt).
