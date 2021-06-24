// See README.md for licensing information.

import Foundation
import CoreGraphics.CGGeometry

/// A value which is representable as an AppleEvent descriptor.
public indirect enum AEValue {
    
    case descriptor(AEDescriptor)
    
    case rootSpecifier(RootSpecifier)
    case objectSpecifier(SingleObjectSpecifier)
    case insertionSpecifier(InsertionSpecifier)
    
    case comparisonTest(ComparisonTest)
    case logicalTest(LogicalTest)
    
    case missingValue
    case symbol(Symbol)
    
    case bool(Bool)
    case int32(Int32)
    case int64(Int64)
    case uint64(UInt64)
    case double(Double)
    case string(String)
    case date(Date)
    
    case list([AEValue])
    case record([AE4 : AEValue])
    
    case fileURL(URL)
    
    case point(CGPoint)
    case rect(CGRect)
    case color(RGBColor)
    
    var query: Query? {
        switch self {
        case let .rootSpecifier(query as Query),
             let .objectSpecifier(query as Query),
             let .insertionSpecifier(query as Query):
            return query
        default:
            return nil
        }
    }
    
    var testClause: TestClause? {
        switch self {
        case let .comparisonTest(testClause as TestClause),
             let .logicalTest(testClause as TestClause):
            return testClause
        default:
            return nil
        }
    }
    
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

public struct RGBColor {
    
    public init(r: UInt16, g: UInt16, b: UInt16) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    public var r, g, b: UInt16
    
}

extension AEValue: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .descriptor(object as Any),
             let .rootSpecifier(object as Any),
             let .objectSpecifier(object as Any),
             let .insertionSpecifier(object as Any),
             let .comparisonTest(object as Any),
             let .logicalTest(object as Any),
             let .symbol(object as Any),
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

extension AEValue: AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        switch self {
        case let .descriptor(descriptor):
            return descriptor
        case let .rootSpecifier(object as AEEncodable),
             let .objectSpecifier(object as AEEncodable),
             let .insertionSpecifier(object as AEEncodable),
             let .comparisonTest(object as AEEncodable),
             let .logicalTest(object as AEEncodable),
             let .symbol(object as AEEncodable),
             let .bool(object as AEEncodable),
             let .int32(object as AEEncodable),
             let .int64(object as AEEncodable),
             let .uint64(object as AEEncodable),
             let .double(object as AEEncodable),
             let .string(object as AEEncodable),
             let .date(object as AEEncodable),
             let .fileURL(object as AEEncodable),
             let .point(object as AEEncodable),
             let .rect(object as AEEncodable),
             let .color(object as AEEncodable):
            return try object.encodeAEDescriptor(app)
        case let .list(list):
            return try list.encodeAEDescriptor(app)
        case let .record(record):
            return try record.encodeAEDescriptor(app)
        case .missingValue:
            return missingValueDesc
        }
    }
    
}
