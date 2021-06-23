//  Originally written by hhas.
//  See README.md for licensing information.

//
//  Extends Swift's generic Optional and collection types so that they encode and decode themselves (since Swift lacks the dynamic introspection capabilities for App to determine how to encode and decode them itself)
//

import Foundation


/******************************************************************************/
// Specifier and Symbol subclasses encode themselves
// Set, Array, Dictionary structs encode and decode themselves

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

/// Whether `desc` is the "missing value" symbol.
func isMissingValue(_ desc: NSAppleEventDescriptor) -> Bool {
    return desc.descriptorType == AE4.Types.type && desc.typeCodeValue == AE4.Classes.missingValue
}

extension Optional: AECodable where Wrapped == AEValue {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        try self.map { try app.encode($0) } ?? missingValueDesc
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        self = isMissingValue(descriptor) ? nil : try app.decode(descriptor)
    }
    
}

extension CGPoint: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        var data = Data(capacity: 2)
        data.append(y)
        data.append(x)
        return NSAppleEventDescriptor(descriptorType: AE4.Types.qdPoint, data: data)!
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        if let point = descriptor.coerce(toDescriptorType: AE4.Types.qdPoint) {
            let data = point.data
            let scalarSize = MemoryLayout<Int16>.size
            
            var y: Int16 = 0
            withUnsafeMutableBytes(of: &y) { y in
                _ = data.copyBytes(to: y, from: 0..<scalarSize)
            }
            var x: Int16 = 0
            withUnsafeMutableBytes(of: &x) { x in
                _ = data.copyBytes(to: x, from: scalarSize..<(2 * scalarSize))
            }
            
            self.init(x: CGFloat(x), y: CGFloat(y))
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension CGRect: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        var data = Data(capacity: 4)
        data.append(minY)
        data.append(minX)
        data.append(maxY)
        data.append(maxX)
        return NSAppleEventDescriptor(descriptorType: AE4.Types.qdRectangle, data: data)!
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        if let rect = descriptor.coerce(toDescriptorType: AE4.Types.qdRectangle) {
            let data = rect.data
            let scalarSize = MemoryLayout<Int16>.size
            
            var y0: Int16 = 0
            withUnsafeMutableBytes(of: &y0) { y0 in
                _ = data.copyBytes(to: y0, from: 0..<scalarSize)
            }
            var x0: Int16 = 0
            withUnsafeMutableBytes(of: &x0) { x0 in
                _ = data.copyBytes(to: x0, from: scalarSize..<(2 * scalarSize))
            }
            var y1: Int16 = 0
            withUnsafeMutableBytes(of: &y1) { y1 in
                _ = data.copyBytes(to: y1, from: (2 * scalarSize)..<(3 * scalarSize))
            }
            var x1: Int16 = 0
            withUnsafeMutableBytes(of: &x1) { x1 in
                _ = data.copyBytes(to: x1, from: (3 * scalarSize)..<(4 * scalarSize))
            }
            
            self.init(x: CGFloat(x0), y: CGFloat(y0), width: CGFloat(x1 - x0), height: CGFloat(y1 - y0))
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension RGBColor: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        var data = Data(capacity: 3)
        data.append(r)
        data.append(g)
        data.append(b)
        return NSAppleEventDescriptor(descriptorType: AE4.Types.rgbColor, data: data)!
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        if let color = descriptor.coerce(toDescriptorType: AE4.Types.rgbColor) {
            let data = color.data
            let scalarSize = MemoryLayout<UInt16>.size
            
            var r: UInt16 = 0
            withUnsafeMutableBytes(of: &r) { r in
                _ = data.copyBytes(to: r, from: 0..<scalarSize)
            }
            var g: UInt16 = 0
            withUnsafeMutableBytes(of: &g) { g in
                _ = data.copyBytes(to: g, from: scalarSize..<(2 * scalarSize))
            }
            var b: UInt16 = 0
            withUnsafeMutableBytes(of: &b) { b in
                _ = data.copyBytes(to: b, from: (2 * scalarSize)..<(3 * scalarSize))
            }
            
            self.init(r: r, g: g, b: b)
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension Data {
    
    mutating func append<Element>(_ newElement: Element) {
        Swift.withUnsafeBytes(of: newElement) {
            append(contentsOf: $0)
        }
    }
    
}

extension Array: AECodable where Element == AEValue {
    
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
                    result.append(try app.decode(descriptor.atIndex(i)!))
                } catch {
                    throw DecodeError(descriptor: descriptor, type: Self.self, message: "Can't decode item \(i) as \(Element.self).")
                }
            }
            self = result
        default:
            self = [try app.decode(descriptor) as Element]
        }
    }
    
}


extension Dictionary: AECodable where Key == Symbol, Value == AEValue {
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        var desc = NSAppleEventDescriptor.record()
        var isCustomRecordType: Bool = false
        if case let .symbol(recordClass) = self[Symbol(code: AE4.Properties.class, type: typeType)] {
            desc = desc.coerce(toDescriptorType: recordClass.code)!
            isCustomRecordType = true
        }
        for (key, value) in self {
            if !(key.code == AE4.Properties.class && isCustomRecordType) {
                desc.setDescriptor(try app.encode(value), forKeyword: key.code)
            }
        }
        return desc
    }
    
    public init(from descriptor: NSAppleEventDescriptor, app: App) throws {
        guard descriptor.isRecordDescriptor else {
            throw DecodeError(descriptor: descriptor, type: Self.self, message: "Not a record.")
        }
        self.init()
        if descriptor.descriptorType != AE4.Types.record {
            self[Symbol(code: AE4.Properties.class, type: typeType)] = .symbol(Symbol(code: descriptor.descriptorType, type: typeType))
        }
        for i in 1..<(descriptor.numberOfItems + 1) {
            let property = descriptor.keywordForDescriptor(at: i)
            self[Symbol(code: property, type: AE4.Types.property)] = try app.decode(descriptor.atIndex(i)!)
        }
    }
    
}
