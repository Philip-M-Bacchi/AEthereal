// See README.md for licensing information.

import Foundation

public class AEEncoder: Encoder {
    
    public static func encode(_ value: Encodable) throws -> AEDescriptor {
        let encoder = AEEncoder()
        try AEthereal.encode(value, to: encoder)
        if let container = encoder.container {
            try setType(container, value)
        }
        return encoder.container!.descriptor
    }
    
    init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }
    
    public var codingPath: [CodingKey]
    
    public var userInfo: [CodingUserInfoKey : Any] {
        [:]
    }
    
    fileprivate var container: AEDescriptorContainer?
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let keyedContainer = KeyedContainer<Key>(codingPath: codingPath)
        container = keyedContainer
        return KeyedEncodingContainer(keyedContainer)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        let unkeyedContainer = UnkeyedContainer(codingPath: codingPath)
        container = unkeyedContainer
        return unkeyedContainer
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        let singleValueContainer = SingleValueContainer(codingPath: codingPath)
        container = singleValueContainer
        return singleValueContainer
    }
    
    private class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol, AEDescriptorContainer {
        
        init(codingPath: [CodingKey]) {
            self.codingPath = codingPath
            self.descriptor = .record()!
        }
        
        var codingPath: [CodingKey]

        var descriptor: AEDescriptor
        
        func encodeNil(forKey key: Key) throws {
        }
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            let encoder = AEEncoder(codingPath: codingPath + [key])
            try AEthereal.encode(value, to: encoder)
            if let container = encoder.container {
                try setType(container, value)
                let ae4Key = try key.ae4()
                if let attribute = AE4.Attribute(rawValue: ae4Key) {
                    descriptor[attribute] = container.descriptor
                } else {
                    descriptor[ae4Key] = container.descriptor
                }
            }
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            let container = KeyedContainer<NestedKey>(codingPath: codingPath + [key])
            descriptor[try! key.ae4()] = container.descriptor
            return KeyedEncodingContainer(container)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            let container = UnkeyedContainer(codingPath: codingPath + [key])
            descriptor[try! key.ae4()] = container.descriptor
            return container
        }
        
        func superEncoder() -> Encoder {
            fatalError()
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            fatalError()
        }
        
    }
    
    private class UnkeyedContainer: UnkeyedEncodingContainer, AEDescriptorContainer {
        
        init(codingPath: [CodingKey], descriptor: AEDescriptor = .list()) {
            self.codingPath = codingPath
            self.descriptor = descriptor
        }
        
        var codingPath: [CodingKey]
        var count: Int {
            descriptor.numberOfItems
        }
        
        var descriptor: AEDescriptor
        
        func encodeNil() throws {
            descriptor.append(.missingValue)
        }
        
        func encode<T>(_ value: T) throws where T : Encodable {
            let encoder = AEEncoder(codingPath: codingPath)
            try AEthereal.encode(value, to: encoder)
            if let container = encoder.container {
                try setType(container, value)
                descriptor.append(container.descriptor)
            }
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            let container = KeyedContainer<NestedKey>(codingPath: codingPath)
            descriptor.append(container.descriptor)
            return KeyedEncodingContainer(container)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let container = UnkeyedContainer(codingPath: codingPath)
            descriptor.append(container.descriptor)
            return container
        }
        
        func superEncoder() -> Encoder {
            fatalError()
        }
        
    }
    
    private class SingleValueContainer: SingleValueEncodingContainer, AEDescriptorContainer {
        
        init(codingPath: [CodingKey]) {
            self.codingPath = codingPath
        }
        
        var codingPath: [CodingKey]
        
        var descriptor: AEDescriptor = .null()
        
        func encodeNil() throws {
        }
        
        func encode(_ value: Bool) throws {
            descriptor = .init(boolean: value)
            try setType(self, value)
        }
        
        func encode(_ value: String) throws {
            descriptor = .init(string: value)
            try setType(self, value)
        }
        
        func encode(_ value: Double) throws {
            descriptor = .init(double: value)
            try setType(self, value)
        }
        
        func encode(_ value: Float) throws {
            descriptor = .init(double: Double(value))
            try setType(self, value)
        }
        
        func encode(_ value: Int) throws {
            descriptor = .init(int64: Int64(value))
            try setType(self, value)
        }
        
        func encode(_ value: Int8) throws {
            descriptor = .init(int32: Int32(value))
            try setType(self, value)
        }
        
        func encode(_ value: Int16) throws {
            descriptor = .init(int32: Int32(value))
            try setType(self, value)
        }
        
        func encode(_ value: Int32) throws {
            descriptor = .init(int32: value)
            try setType(self, value)
        }
        
        func encode(_ value: Int64) throws {
            descriptor = .init(int64: value)
            try setType(self, value)
        }
        
        func encode(_ value: UInt) throws {
            descriptor = .init(uint64: UInt64(value))
            try setType(self, value)
        }
        
        func encode(_ value: UInt8) throws {
            descriptor = .init(int32: Int32(value))
            try setType(self, value)
        }
        
        func encode(_ value: UInt16) throws {
            descriptor = .init(int32: Int32(value))
            try setType(self, value)
        }
        
        func encode(_ value: UInt32) throws {
            descriptor = .init(uint32: UInt32(value))
            try setType(self, value)
        }
        
        func encode(_ value: UInt64) throws {
            descriptor = .init(uint64: UInt64(value))
            try setType(self, value)
        }
        
        func encode<T>(_ value: T) throws where T : Encodable {
            let encoder = AEEncoder(codingPath: codingPath)
            try AEthereal.encode(value, to: encoder)
            if let container = encoder.container {
                descriptor = container.descriptor
            }
            try setType(self, value)
        }
        
    }
    
}

public enum AECodingError: Swift.Error {
    
    case keyNotAE4Representable(CodingKey)
    
}

extension CodingKey {
    
    /// The value to use in an AE4-indexed collection.
    public var ae4Value: AE4? {
        intValue.flatMap { AE4(exactly: $0) }
    }
    
    func ae4() throws -> AE4 {
        guard let ae4Value = self.ae4Value else {
            throw AECodingError.keyNotAE4Representable(self)
        }
        return ae4Value
    }

    /// Creates a new instance from the specified AE4 code.
    ///
    /// If the value passed as `ae4Value` does not correspond to any instance of
    /// this type, the result is `nil`.
    ///
    /// - parameter ae4Value: The AE4 code value of the desired key.
    public init?(ae4Value: AE4) {
        self.init(intValue: Int(ae4Value))
    }
    
}

public protocol AE4CodingKey: CodingKey {
}

extension AE4CodingKey where Self: RawRepresentable, RawValue == AE4 {
    
    public var intValue: Int? {
        Int(rawValue)
    }
    
    public var stringValue: String {
        String(ae4Code: rawValue)
    }
    
    public init?(intValue: Int) {
        guard let ae4 = AE4(exactly: intValue) else {
            return nil
        }
        self.init(rawValue: ae4)
    }
    
    public init?(stringValue: String) {
        guard let ae4Value = stringValue.ae4Code else {
            return nil
        }
        self.init(ae4Value: ae4Value)
    }
    
}

public protocol AETyped {
    
    var aeType: AE4.AEType { get }
    
}

// For common case of AE4 enums.
extension AETyped where Self: RawRepresentable, RawValue == AE4 {
    
    public var aeType: AE4.AEType {
        .enumerated
    }
    
}

private protocol AEDescriptorContainer: AnyObject {
    
    var codingPath: [CodingKey] { get }
    var descriptor: AEDescriptor { get set }
    
}

private func encode(_ value: Encodable, to encoder: Encoder) throws {
    // This switch statement is just for convenience.
    // We could achieve the same effect by wrapping each of these
    // types in a struct with custom encode(to:), but that would
    // involve a lot of useless typecasting.
    // Even JSONEncoder has special handling for some types (e.g., Date),
    // so I feel this is justified.
    // Also see the matching switch in AEDecoder.
    switch value {
    case let data as Data:
        try AEDescriptor(type: .data, data: data).encode(to: encoder)
    case let date as Date:
        try AEDescriptor(date: date).encode(to: encoder)
    case let point as CGPoint:
        try AEDescriptor(point: point).encode(to: encoder)
    case let rect as CGRect:
        try AEDescriptor(rect: rect).encode(to: encoder)
    default:
        try value.encode(to: encoder)
    }
}

private func setType(_ descriptorContainer: AEDescriptorContainer, _ value: Any) throws {
    let descriptor = descriptorContainer.descriptor
    if let typed = value as? AETyped {
        if let coerced = descriptor.coerce(to: typed.aeType) {
            // Should work for record descriptors
            descriptorContainer.descriptor = coerced
        } else {
            // Should work for all other descriptors
            descriptorContainer.descriptor = AEDescriptor(type: typed.aeType, data: descriptor.data)
        }
        
    }
}
