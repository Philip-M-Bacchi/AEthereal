// See README.md for licensing information.

import Foundation

public class AEDecoder: Decoder {
    
    public static func decode<T: Decodable>(_ descriptor: AEDescriptor, userInfo: [CodingUserInfoKey : Any] = [:]) throws -> T {
        let decoder = AEDecoder(descriptor: descriptor, userInfo: userInfo)
        guard let decoded: T = try AEthereal.decode(from: decoder) else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(descriptor) cannot be decoded as \(T.self)"))
        }
        return decoded
    }
    
    public convenience init(descriptor: AEDescriptor, userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.init(codingPath: [], userInfo: userInfo, descriptor: descriptor)
    }
    
    fileprivate init(codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey : Any], descriptor: AEDescriptor) {
        self.codingPath = codingPath
        self.userInfo = userInfo.merging([.descriptor: descriptor], uniquingKeysWith: { old, new in new })
        self.descriptor = descriptor
    }
    
    fileprivate convenience init(decoder: AEDecoder, descriptor: AEDescriptor) {
        self.init(codingPath: decoder.codingPath, userInfo: decoder.userInfo, descriptor: descriptor)
    }
    
    public var codingPath: [CodingKey]
    
    public var userInfo: [CodingUserInfoKey : Any]
    
    var descriptor: AEDescriptor
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(try KeyedContainer<Key>(decoder: self, descriptor: descriptor))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try UnkeyedContainer(decoder: self, descriptor: descriptor)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(decoder: self, descriptor: descriptor)
    }
    
    private class KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol, AEDescriptorContainer {
        
        init(decoder: AEDecoder, descriptor: AEDescriptor) throws {
            self.decoder = decoder
            guard descriptor.isRecordDescriptor else {
                throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(descriptor.debugDescription) is not a record descriptor"))
            }
            self.descriptor = descriptor
        }
        
        var decoder: AEDecoder
        var codingPath: [CodingKey] {
            decoder.codingPath
        }

        var descriptor: AEDescriptor
        
        var allKeys: [Key] {
            descriptor.allKeys.compactMap { Key(ae4Value: $0) }
        }
        
        func contains(_ key: Key) -> Bool {
            guard let ae4Key = try? key.ae4() else {
                return false
            }
            return descriptor[ae4Key] != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            !contains(key)
        }
        
        private func value<Key>(for key: Key) throws -> AEDescriptor where Key : CodingKey {
            guard let value = descriptor[try key.ae4()] else {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found in \(descriptor.debugDescription)"))
            }
            return value
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            let decoder = AEDecoder(codingPath: codingPath + [key], userInfo: decoder.userInfo, descriptor: try value(for: key))
            guard let decoded: T = try AEthereal.decode(from: decoder) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(descriptor) cannot be decoded as \(type)"))
            }
            return decoded
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            KeyedDecodingContainer(try KeyedContainer<NestedKey>(decoder: decoder, descriptor: try value(for: key)))
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            try UnkeyedContainer(decoder: decoder, descriptor: try value(for: key))
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError()
        }
        
    }
    
    private class UnkeyedContainer: UnkeyedDecodingContainer, AEDescriptorContainer {
        
        init(decoder: AEDecoder, descriptor: AEDescriptor) throws {
            self.decoder = decoder
            self.descriptor = descriptor
        }
        
        var decoder: AEDecoder
        var codingPath: [CodingKey] {
            decoder.codingPath
        }
        var count: Int? {
            descriptor.numberOfItems
        }
        var isAtEnd: Bool {
            currentIndex == count
        }
        var currentIndex: Int = 1
        
        var descriptor: AEDescriptor
        
        private func withNext<Result>(do action: (AEDescriptor) throws -> (Result, shouldIncrement: Bool)) throws -> Result {
            guard let next = descriptor.atIndex(currentIndex) else {
                throw DecodingError.valueNotFound(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "No more values"))
            }
            let (result, shouldIncrement) = try action(next)
            if shouldIncrement {
                currentIndex += 1
            }
            return result
        }
        
        func decodeNil() throws -> Bool {
            try withNext {
                ($0.isMissingValue, shouldIncrement: $0.isMissingValue)
            }
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try withNext { descriptor in
                let decoder = AEDecoder(decoder: decoder, descriptor: descriptor)
                guard let decoded: T = try AEthereal.decode(from: decoder) else {
                    throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(descriptor) cannot be decoded as \(type)"))
                }
                return (decoded, shouldIncrement: true)
            }
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            try withNext { descriptor in
                (KeyedDecodingContainer(try KeyedContainer<NestedKey>(decoder: decoder, descriptor: descriptor)), shouldIncrement: true)
            }
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            try withNext { descriptor in
                (try UnkeyedContainer(decoder: decoder, descriptor: descriptor), shouldIncrement: true)
            }
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
    }
    
    private class SingleValueContainer: SingleValueDecodingContainer, AEDescriptorContainer {
        
        init(decoder: AEDecoder, descriptor: AEDescriptor) {
            self.decoder = decoder
            self.descriptor = descriptor
        }
        
        var decoder: AEDecoder
        var codingPath: [CodingKey] {
            decoder.codingPath
        }
        
        var descriptor: AEDescriptor
        
        func decodeNil() -> Bool {
            descriptor.data.isEmpty
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            descriptor.booleanValue
        }
        
        func decode(_ type: String.Type) throws -> String {
            try descriptor.stringValue
                ?? String(data: descriptor.data, encoding: .utf8)
                ?? { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Actual value was \(descriptor)")) }()
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            descriptor.doubleValue
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            Float(descriptor.doubleValue)
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            try descriptor.int64Value.flatMap { Int(exactly: $0) }
                ?? { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Actual value was \(descriptor)")) }()
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            Int8(descriptor.int32Value)
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            Int16(descriptor.int32Value)
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            descriptor.int32Value
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            try descriptor.int64Value
                ?? { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Actual value was \(descriptor)")) }()
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            try descriptor.uint64Value.flatMap { UInt(exactly: $0) }
                ?? { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Actual value was \(descriptor)")) }()
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            UInt8(descriptor.int32Value)
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            UInt16(descriptor.int32Value)
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            descriptor.uint64Value.flatMap { UInt32(exactly: $0) } ??
                UInt32(descriptor.typeCodeValue)
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            try descriptor.uint64Value
                ?? { throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Actual value was \(descriptor)")) }()
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            let decoder = AEDecoder(decoder: decoder, descriptor: descriptor)
            guard let decoded: T = try AEthereal.decode(from: decoder) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(descriptor) cannot be decoded as \(type)"))
            }
            return decoded
        }
        
    }
    
}

private protocol AEDescriptorContainer {
    
    var descriptor: AEDescriptor { get }
    
}

extension CodingUserInfoKey {
    
    /// Corresponds to the AEDescriptor being decoded.
    public static let descriptor = CodingUserInfoKey(rawValue: "AEthereal.descriptor")!
    
}

private func decode<T: Decodable>(from decoder: Decoder) throws -> T? {
    // This switch statement is just for convenience.
    // We could achieve the same effect by wrapping each of these
    // types in a struct with custom init(from:), but that would
    // involve a lot of useless typecasting.
    // Even JSONDecoder has special handling for some types (e.g., Date),
    // so I feel this is justified.
    // Also see the matching switch in AEEncoder.
    switch T.self {
    case Data.self:
        return try AEDescriptor(from: decoder).data as Data? as? T
    case Date.self:
        return try AEDescriptor(from: decoder).dateValue as Date? as? T
    case CGPoint.self:
        return try AEDescriptor(from: decoder).pointValue as CGPoint? as? T
    case CGRect.self:
        return try AEDescriptor(from: decoder).rectValue as CGRect? as? T
    default:
        return try T.init(from: decoder)
    }
}

// Pattern matching for above switch statement.
private func ~=<T, U>(_ lhs: T.Type, _ rhs: U.Type) -> Bool {
    lhs is U
}
