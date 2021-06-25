//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation
import CoreGraphics.CGGeometry

public struct AEFileURL: Codable {
    
    public init(url: URL) {
        self.url = url
    }
    
    public var url: URL
    
    public func encode(to encoder: Encoder) throws {
        try AEDescriptor(fileURL: url).encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        if let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor {
            guard let url = descriptor.fileURLValue else {
                throw DecodingError.typeMismatch(AEFileURL.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected a file URL, but descriptor is \(descriptor)"))
            }
            self.init(url: url)
        } else {
            let container = try decoder.singleValueContainer()
            self.init(url: try container.decode(URL.self))
        }
    }
    
}

extension RGBColor: Codable {
    
    public func encode(to encoder: Encoder) throws {
        try AEDescriptor(rgbColor: self).encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        if let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor {
            guard let rgbColor = descriptor.rgbColorValue else {
                throw DecodingError.typeMismatch(AEFileURL.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected a point, but descriptor is \(descriptor)"))
            }
            self = rgbColor
        } else {
            var container = try decoder.unkeyedContainer()
            self.init(
                r: try container.decode(UInt16.self),
                g: try container.decode(UInt16.self),
                b: try container.decode(UInt16.self)
            )
        }
    }
    
}

extension Data {
    
    mutating func append<Element>(_ newElement: Element) {
        Swift.withUnsafeBytes(of: newElement) {
            append(contentsOf: $0)
        }
    }
    
}

// TODO: Remove if not needed, i.e., if try container().decode([AEDescriptor].self)
//       works as used in AEValue.init(from:).
//extension Array where Element == AEDescriptor {
//
//    public init(aeListFrom decoder: Decoder) throws {
//        var container = try decoder.unkeyedContainer()
//        self.init()
//        while !container.isAtEnd {
//            append(try container.decode(AEDescriptor.self))
//        }
//    }
//
//}

extension Dictionary where Key == AE4, Value == AEDescriptor {
    
    public init(aeRecordFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        for key in container.allKeys {
            self[try key.ae4()] = try container.decode(AEDescriptor.self, forKey: key)
        }
    }
    
    private struct CodingKeys: RawRepresentable, AE4CodingKey {
        
        typealias RawValue = AE4
        
        init?(rawValue: AE4) {
            self.rawValue = rawValue
        }
        
        var rawValue: AE4
        
    }
    
}

// This goofy solution is due to Swift's "opening existentials" feature
// only being exposed via protocol extension methods.
// https://stackoverflow.com/questions/33112559/protocol-doesnt-conform-to-itself/43408193#43408193
extension Encodable {
    
    public func encode<Key>(to container: inout KeyedEncodingContainer<Key>, forKey key: Key) throws {
        try container.encode(self, forKey: key)
    }
    
    public func encode(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }
    
    public func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
    
}
