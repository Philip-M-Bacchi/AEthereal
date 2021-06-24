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
    func encodeAEDescriptor(_ app: App) throws -> AEDescriptor
}

public protocol AEDecodable {
    init(from descriptor: AEDescriptor, app: App) throws
}

public typealias AECodable = AEEncodable & AEDecodable

extension Optional: AECodable where Wrapped == AEValue {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try self.map { try app.encode($0) } ?? .missingValue
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        self = descriptor.isMissingValue ? nil : try app.decode(descriptor)
    }
    
}

extension CGPoint: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        var data = Data(capacity: 2)
        data.append(y)
        data.append(x)
        return AEDescriptor(type: .qdPoint, data: data)!
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let point = descriptor.coerce(to: .qdPoint) {
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
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        var data = Data(capacity: 4)
        data.append(minY)
        data.append(minX)
        data.append(maxY)
        data.append(maxX)
        return AEDescriptor(type: .qdRectangle, data: data)!
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let rect = descriptor.coerce(to: .qdRectangle) {
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
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        var data = Data(capacity: 3)
        data.append(r)
        data.append(g)
        data.append(b)
        return AEDescriptor(type: .rgbColor, data: data)!
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let color = descriptor.coerce(to: .rgbColor) {
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

extension Sequence where Element: AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try reduce(into: AEDescriptor.list()) {
            $0.insert(try $1.encodeAEDescriptor(app), at: 0)
        }
    }
    
}
extension Array: AEEncodable where Element == AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try reduce(into: AEDescriptor.list()) {
            $0.insert(try $1.encodeAEDescriptor(app), at: 0)
        }
    }
    
}
extension Array: AEDecodable where Element == AEValue {
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        guard let list = descriptor.coerce(to: .list) else {
            throw DecodeError(descriptor: descriptor, type: Self.self)
        }
        self.init()
        for i in 1..<(list.numberOfItems + 1) { // bug workaround for zero-length range: 1...0 throws error, but 1..<1 doesn't
            do {
                self.append(try app.decode(list.atIndex(i)!))
            } catch {
                throw DecodeError(descriptor: list, type: Self.self, message: "Can't decode item \(i) as \(Element.self).")
            }
        }
    }
    
}

extension Dictionary where Key == AE4, Value: AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try reduce(into: AEDescriptor.record()) {
            $0[$1.key] = try $1.value.encodeAEDescriptor(app)
        }
    }
    
}
extension Dictionary: AEEncodable where Key == AE4, Value == AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try reduce(into: AEDescriptor.record()) {
            $0[$1.key] = try $1.value.encodeAEDescriptor(app)
        }
    }
    
}
extension Dictionary: AEDecodable where Key == AE4, Value == AEValue {
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        guard descriptor.isRecordDescriptor else {
            throw DecodeError(descriptor: descriptor, type: Self.self)
        }
        self.init()
        for i in 1..<(descriptor.numberOfItems + 1) {
            self[descriptor.keywordForDescriptor(at: i)] = try app.decode(descriptor.atIndex(i)!)
        }
    }
    
}

extension Bool: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        AEDescriptor(boolean: self)
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        self = descriptor.booleanValue
    }
    
}

extension Int: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        // Note: to maximize application compatibility, always preferentially encode integers as typeSInt32, as that's the traditional integer type recognized by all apps. (In theory, encoding as typeSInt64 shouldn't be a problem as apps should coerce to whatever type they actually require before decoding, but not-so-well-designed Carbon apps sometimes explicitly typecheck instead, so will fail if the descriptor isn't the assumed typeSInt32.)
        if Int(Int32.min) <= self && self <= Int(Int32.max) {
            return AEDescriptor(int32: Int32(self))
        }
        if app.isInt64Compatible {
            return AEDescriptor(int64: Int64(self))
        }
        return AEDescriptor(double: Double(self))
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let int64 = descriptor.int64Value {
            self = Int(int64)
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension UInt: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        if self <= UInt(Int32.max) {
            return AEDescriptor(int32: Int32(self))
        }
        if app.isInt64Compatible {
            return AEDescriptor(uint64: UInt64(self))
        }
        return AEDescriptor(double: Double(self))
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let uint64 = descriptor.uint64Value {
            self = UInt(uint64)
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension Int32: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        return AEDescriptor(int32: self)
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        self = descriptor.int32Value
    }
    
}

extension UInt32: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        if self <= UInt32(Int32.max) {
            return AEDescriptor(int32: Int32(self))
        }
        if app.isInt64Compatible {
            return AEDescriptor(uint32: self)
        }
        return AEDescriptor(double: Double(self))
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let uint64 = descriptor.uint64Value {
            self = UInt32(uint64)
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension Int64: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        if self >= Int64(Int32.min) && self <= Int64(Int32.max) {
            return AEDescriptor(int32: Int32(self))
        }
        if app.isInt64Compatible {
            return AEDescriptor(int64: self)
        }
        return AEDescriptor(double: Double(self))
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let int64 = descriptor.int64Value {
            self = int64
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension UInt64: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        if self <= UInt64(Int32.max) {
            return AEDescriptor(int32: Int32(self))
        }
        if app.isInt64Compatible {
            return AEDescriptor(uint64: self)
        }
        return AEDescriptor(double: Double(self))
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let uint64 = descriptor.uint64Value {
            self = uint64
        }
        throw DecodeError(descriptor: descriptor, type: Self.self)
    }
    
}

extension Float: AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        AEDescriptor(double: Double(self))
    }
    
}

extension Double: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        AEDescriptor(double: self)
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        self = descriptor.doubleValue
    }
    
}

extension String: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        AEDescriptor(string: self)
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let string = descriptor.stringValue {
            self = string
        } else {
            throw DecodeError(descriptor: descriptor, type: Self.self)
        }
    }
    
}

extension Date: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        AEDescriptor(date: self)
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        if let date = descriptor.dateValue {
            self = date
        } else {
            throw DecodeError(descriptor: descriptor, type: Self.self)
        }
    }
    
}

extension URL: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        if isFileURL {
            return AEDescriptor(fileURL: self)
        }
        throw EncodeError(object: self)
    }
    
    public init(from descriptor: AEDescriptor, app: App) throws {
        guard let fileURL = descriptor.fileURLValue else {
            throw DecodeError(descriptor: descriptor, type: Self.self)
        }
        self = fileURL
    }
    
}
