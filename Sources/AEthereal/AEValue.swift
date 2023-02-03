// See README.md for licensing information.

import CoreGraphics.CGGeometry
import Foundation

/// A value which is representable as an AppleEvent descriptor.
public indirect enum AEValue {
    
    case query(Query)
    
    case missingValue
    case type(AE4.AEType)
    case `enum`(AE4.AEEnum)
    
    case bool(Bool)
    case int32(Int32)
    case int64(Int64)
    case uint64(UInt64)
    case double(Double)
    case string(String)
    case date(Date)
    
    case list([AEDescriptor])
    case record([AE4 : AEDescriptor])
    
    case fileURL(AEFileURL)
    
    case point(CGPoint)
    case rect(CGRect)
    case color(RGBColor)
    
    func int32() throws -> Int32 {
        try {
            switch self {
            case let .int32(int32):
                return int32
            case let .int64(int64):
                return Int32(exactly: int64)
            case let .uint64(uint64):
                return Int32(exactly: uint64)
            default:
                return nil
            }
        }() ?? {
            throw WrongType(self, type: Int32.self)
        }()
    }
    
    func int64() throws -> Int64 {
        try {
            switch self {
            case let .int32(int32):
                return Int64(exactly: int32)
            case let .int64(int64):
                return int64
            case let .uint64(uint64):
                return Int64(exactly: uint64)
            default:
                return nil
            }
        }() ?? {
            throw WrongType(self, type: Int64.self)
        }()
    }
    
    func uint64() throws -> UInt64 {
        try {
            switch self {
            case let .int32(int32):
                return UInt64(exactly: int32)
            case let .int64(int64):
                return UInt64(exactly: int64)
            case let .uint64(uint64):
                return uint64
            default:
                return nil
            }
        }() ?? {
            throw WrongType(self, type: UInt64.self)
        }()
    }
    
}

extension AEValue: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .query(object as Any),
             let .type(object as Any),
             let .enum(object as Any),
             let .bool(object as Any),
             let .int32(object as Any),
             let .int64(object as Any),
             let .uint64(object as Any),
             let .double(object as Any),
             let .string(object as Any),
             let .date(object as Any),
             let .list(object as Any),
             let .record(object as Any),
             let .fileURL(object as Any),
             let .point(object as Any),
             let .rect(object as Any),
             let .color(object as Any):
            return "\(object)"
        case .missingValue:
            return "missing value"
        }
    }
    
}

extension AEValue: Codable {
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .query(object as Encodable),
             let .type(object as Encodable),
             let .enum(object as Encodable),
             let .bool(object as Encodable),
             let .int32(object as Encodable),
             let .int64(object as Encodable),
             let .uint64(object as Encodable),
             let .double(object as Encodable),
             let .string(object as Encodable),
             let .date(object as Encodable),
             let .list(object as Encodable),
             let .record(object as Encodable),
             let .fileURL(object as Encodable),
             let .point(object as Encodable),
             let .rect(object as Encodable),
             let .color(object as Encodable):
            // Invoke special handling if needed
            // (see also https://forums.swift.org/t/how-to-encode-objects-of-unknown-type/12253/5)
            var container = encoder.singleValueContainer()
            try object.encode(to: &container)
        case .missingValue:
            return try AEDescriptor.missingValue.encode(to: encoder)
        }
    }
    
    public init(from decoder: Decoder) throws {
        guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Can only decode from an AEDescriptor"))
        }
        func container() throws -> SingleValueDecodingContainer {
            try decoder.singleValueContainer()
        }
        switch descriptor.type {
        case .null, .currentContainer, .objectBeingExamined, .objectSpecifier, .insertionLoc:
            self = .query(try container().decode(Query.self))
        
        case .type:
            self = descriptor.isMissingValue ? .missingValue : .type(try container().decode(AE4.AEType.self))
        case .enumerated, .property, .keyword, .absoluteOrdinal:
            self = .enum(try container().decode(AE4.AEEnum.self))
        
        case .true, .false, .boolean:
            self = .bool(try container().decode(Bool.self))
        case .sInt32, .sInt16:
            self = .int32(try container().decode(Int32.self))
        case .sInt64:
            self = .int64(try container().decode(Int64.self))
        case .uInt64, .uInt32, .uInt16:
            self = .uint64(try container().decode(UInt64.self))
        case ._128BitFloatingPoint, .ieee64BitFloatingPoint, .ieee32BitFloatingPoint:
            self = .double(try container().decode(Double.self))
        case .text, .intlText, .utf8Text, .utf16ExternalRepresentation, .styledText, .unicodeText, .version:
            self = .string(try container().decode(String.self))
        case .longDateTime:
            self = .date(try container().decode(Date.self))
            
        case .list:
            self = .list(try container().decode([AEDescriptor].self))
        case .record:
            self = .record(try [AE4 : AEDescriptor](aeRecordFrom: decoder))
            
        case .alias, .bookmarkData, .fileURL, .fsRef:
            self = .fileURL(try container().decode(AEFileURL.self))
            
        case .qdPoint:
            self = .point(try container().decode(CGPoint.self))
        case .qdRectangle:
            self = .rect(try container().decode(CGRect.self))
        case .rgbColor:
            self = .color(try container().decode(RGBColor.self))
            
        // note: while there are also several AEAddressDesc types used to identify applications, these are very rarely used as command results (e.g. the `choose application` OSAX) and there's little point decoding them anway as the only type they can automatically be mapped to is AEApplication, which has only minimal functionality anyway. Also unsupported are unit types as they only cover a handful of measurement types and in practice aren't really used for anything except measurement conversions in AppleScript.
        default:
            if descriptor.isRecordDescriptor {
                self = .record(try [AE4 : AEDescriptor](aeRecordFrom: decoder))
            }
            throw DecodingError.typeMismatch(AEValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown type of AEDescriptor"))
        }
    }
    
}
