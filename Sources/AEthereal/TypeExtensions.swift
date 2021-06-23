//  Originally written by hhas.
//  See README.md for licensing information.

//
//  Extends Swift's generic Optional and collection types so that they encode and decode themselves (since Swift lacks the dynamic introspection capabilities for App to determine how to encode and decode them itself)
//

import Foundation


/******************************************************************************/
// Specifier and Symbol subclasses encode themselves
// Set, Array, Dictionary structs encode and decode themselves
// Optional and MayBeMissing enums encode and decode themselves

public protocol AEEncodable {
    func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor
}

public protocol AEDecodable {
    init?(from descriptor: NSAppleEventDescriptor, app: App) throws
}

public typealias AECodable = AEEncodable & AEDecodable


/******************************************************************************/
// `missing value` constant

// note: this design is not yet finalized (ideally we'd just map cMissingValue to nil, but returning nil for commands whose return type is `Any` is a PITA as all of Swift's normal unboxing techniques break, and the only way to unbox is to cast from Any to Optional<T> first, which in turn requires that T is known in advance, in which case what's the point of returning Any in the first place?)

let missingValueDesc = NSAppleEventDescriptor(typeCode: AE4.Classes.missingValue)


// unlike Swift's `nil` (which is actually an infinite number of values since Optional<T>.none is generic), there is only ever one `MissingValue`, which means it should behave sanely when cast to and from `Any`

public enum MissingValueType: CustomStringConvertible, AECodable {
    
    case missingValue
    
    init() { self = .missingValue }
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        return missingValueDesc
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        self.init()
    }
    
    public var description: String { return "MissingValue" }
}

public let MissingValue = MissingValueType() // the `missing value` constant; serves a similar purpose to `Optional<T>.none` (`nil`), except that it's non-generic so isn't a giant PITA to deal with when casting to/from `Any`


// TO DO: define `==`/`!=` operators that treat MayBeMissing<T>.missing(…) and MissingValue and Optional<T>.none as equivalent? Or get rid of `MayBeMissing` enum and (if possible/practical) support `Optional<T> as? MissingValueType` and vice-versa?

// define a generic type for use in command's return type that allows the value to be missing, e.g. `Contacts().people.birthDate.get() as [MayBeMissing<String>]`

// TO DO: it may be simpler for users if commands always return Optional<T>.none when an Optional return type is specified, and MissingValue when one is not

public enum MayBeMissing<T>: AECodable { // TO DO: rename 'MissingOr<T>'? this'd be more in keeping with TypeSupportSpec-generated enum names (e.g. 'IntOrStringOrMissing')
    case value(T)
    case missing(MissingValueType)
    
    public init(_ value: T) {
        switch value {
        case is MissingValueType:
            self = .missing(MissingValue)
        default:
            self = .value(value)
        }
    }
    
    public init() {
        self = .missing(MissingValue)
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        switch self {
        case .value(let value):
            return try app.encode(value)
        case .missing(_):
            return missingValueDesc
        }
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        if isMissingValue(descriptor) {
            self = .missing(MissingValue)
        } else {
            self = .value(try app.decode(descriptor) as T)
        }
    }
    
    public var value: T? { // unbox the actual value, or return `nil` if it was MissingValue; this should allow users to bridge safely from MissingValue to nil
        switch self {
        case .value(let value):
            return value
        case .missing(_):
            return nil
        }
    }
}


func isMissingValue(_ desc: NSAppleEventDescriptor) -> Bool { // check if the given AEDesc is the `missing value` constant
    return desc.descriptorType == AE4.Types.type && desc.typeCodeValue == AE4.Classes.missingValue
}

// allow optionals to be used in place of MayBeMissing… arguably, MayBeMissing won't be needed if this works

extension Optional: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        switch self {
        case .some(let value):
            return try app.encode(value)
        case .none:
            return missingValueDesc
        }
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        if isMissingValue(descriptor) {
            self = .none
        } else {
            self = .some(try app.decode(descriptor))
        }
    }
    
}


/******************************************************************************/
// extend Swift's standard collection types to encode and decode themselves


extension Set: AECodable { // note: AEM doesn't define a standard AE type for Sets, so encode/decode as typeAEList (we'll assume client code has its own reasons for suppling/requesting Set<T> instead of Array<T>)
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        let desc = NSAppleEventDescriptor.list()
        for item in self { desc.insert(try app.encode(item), at: 0) }
        return desc
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        var result = Set<Element>()
        switch descriptor.descriptorType {
        case AE4.Types.list:
            for i in 1..<(descriptor.numberOfItems+1) { // bug workaround for zero-length range: 1...0 throws error, but 1..<1 doesn't
                do {
                    result.insert(try app.decode(descriptor.atIndex(i)!) as Element)
                } catch {
                    throw DecodeError(app: app, descriptor: descriptor, type: Self.self, message: "Can't decode item \(i) as \(Element.self).")
                }
            }
        default:
            result.insert(try app.decode(descriptor) as Element)
        }
        self = result
    }
    
}


extension Array: AECodable {
    
    // TO DO: protocol hierarchy for Swift's various numeric types is both complicated and useless; see about factoring out `Int(n) as! Element` as a block, in which case copy-paste can be replaced with generic
    
    private static func decodeInt16Array(_ desc: NSAppleEventDescriptor, app: App, indexes: [Int]) throws -> [Element] {
        if Element.self == Int.self { // common case
            var result = [Element]()
            let data = desc.data
            for i in indexes { // QDPoint is YX, so swap to give [X,Y]
                var n: Int16 = 0
                (data as NSData).getBytes(&n, range: NSRange(location: i*MemoryLayout<Int16>.size, length: MemoryLayout<Int16>.size))
                result.append(Int(n) as! Element) // note: can't use Element(n) here as Swift doesn't define integer constructors in IntegerType protocol (but does for FloatingPointType)
            }
            return result
        } else { // for any other Element, decode as Int then repack as AEList of typeSInt32, and [try to] decode that as [Element] (bit lazy, but will do)
            return try self.init(from: try app.encode(app.decode(desc) as [Int]), app: app)
        }
    }
    
    private static func decodeUInt16Array(_ desc: NSAppleEventDescriptor, app: App, indexes:[Int]) throws -> [Element] {
        if Element.self == Int.self { // common case
            var result = [Element]()
            let data = desc.data
            for i in indexes { // QDPoint is YX, so swap to give [X,Y]
                var n: UInt16 = 0
                (data as NSData).getBytes(&n, range: NSRange(location: i*MemoryLayout<UInt16>.size, length: MemoryLayout<UInt16>.size))
                result.append(Int(n) as! Element) // note: can't use Element(n) here as Swift doesn't define integer constructors in IntegerType protocol (but does for FloatingPointType)
            }
            return result
        } else { // for any other Element, decode as Int then repack as AEList of typeSInt32, and [try to] decode that as [Element] (bit lazy, but will do)
            return try self.init(from: try app.encode(app.decode(desc) as [Int]), app: app)
        }
    }
    
    //
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        let desc = NSAppleEventDescriptor.list()
        for item in self { desc.insert(try app.encode(item), at: 0) }
        return desc
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        switch descriptor.descriptorType {
        case AE4.Types.list:
            var result = [Element]()
            for i in 1..<(descriptor.numberOfItems+1) { // bug workaround for zero-length range: 1...0 throws error, but 1..<1 doesn't
                do {
                    result.append(try app.decode(descriptor.atIndex(i)!) as Element)
                } catch {
                    throw DecodeError(app: app, descriptor: descriptor, type: Self.self, message: "Can't decode item \(i) as \(Element.self).")
                }
            }
            self = result
            // note: coercing QD types to typeAEList and decoding those would be simpler, but while AEM provides coercion handlers for coercing e.g. typeAEList to typeQDPoint, it doesn't provide handlers for the reverse (coercing a typeQDPoint desc to typeAEList merely produces a single-item AEList containing the original typeQDPoint, not a 2-item AEList of typeSInt16)
        case AE4.Types.qdPoint: // SInt16[2]
            self = try Array<Element>.decodeInt16Array(descriptor, app: app, indexes: [1,0]) // QDPoint is YX; swap to give [X,Y]
        case AE4.Types.qdRectangle: // SInt16[4]
            self = try Array<Element>.decodeInt16Array(descriptor, app: app, indexes: [1,0,3,2]) // QDRectangle is Y0X0Y1X1; swap to give [X0,Y0,X1,Y1]
        case AE4.Types.rgbColor: // UInt16[3] (used by older Carbon apps; Cocoa apps use lists)
            self = try Array<Element>.decodeUInt16Array(descriptor, app: app, indexes: [0,1,2])
        default:
            self = [try app.decode(descriptor) as Element]
        }
    }
    
}


extension Dictionary: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        var desc = NSAppleEventDescriptor.record()
        var isCustomRecordType: Bool = false
        if let key = Symbol(code: AE4.Properties.class, type: typeType) as? Key, let recordClass = self[key] as? Symbol { // TO DO: confirm this works
            desc = desc.coerce(toDescriptorType: recordClass.code)!
            isCustomRecordType = true
        }
        for (key, value) in self {
            guard let keySymbol = key as? Symbol else {
                throw PackError(object: key, message: "Can't encode non-Symbol dictionary key of type: \(type(of: key))")
            }
            if !(keySymbol.code == AE4.Properties.class && isCustomRecordType) {
                desc.setDescriptor(try app.encode(value), forKeyword: keySymbol.code)
            }
        }
        return desc
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        if !descriptor.isRecordDescriptor {
            throw DecodeError(app: app, descriptor: descriptor, type: Self.self, message: "Not a record.")
        }
        var result = [Key:Value]()
        if descriptor.descriptorType != AE4.Types.record {
            if let key = Symbol(code: AE4.Properties.class, type: typeType) as? Key,
                let value = Symbol(code: descriptor.descriptorType, type: typeType) as? Value {
                result[key] = value
            }
        }
        for i in 1..<(descriptor.numberOfItems + 1) {
            let property = descriptor.keywordForDescriptor(at: i)
            // decode record property whose key is a four-char code (typically corresponding to a dictionary-defined property name)
            guard let key = Symbol(code: property, type: AE4.Types.property) as? Key else {
                throw DecodeError(app: app, descriptor: descriptor, type: Key.self,
                                  message: "Can't decode record keys as non-Symbol type: \(Key.self)")
            }
            do {
                result[key] = try app.decode(descriptor.atIndex(i)!) as Value
            } catch {
                throw DecodeError(app: app, descriptor: descriptor, type: Value.self,
                                  message: "Can't decode value of record's \(key) property as Swift type: \(Value.self)")
            }
        }
        self = result
    }
    
}

// specialized return type for use in commands to return the _entire_ reply AppleEvent as a raw AppleEvent descriptor

public struct ReplyEventDescriptor {
    
    let descriptor: NSAppleEventDescriptor // the reply AppleEvent
    
    public var result: NSAppleEventDescriptor? { // the application-returned result value, if any
        return descriptor.paramDescriptor(forKeyword: keyDirectObject)
    }
    
    public var errorNumber: Int { // the application-returned error number, if any; 0 = noErr
        return Int(descriptor.paramDescriptor(forKeyword: keyErrorNumber)?.int32Value ?? 0)
    }
}

