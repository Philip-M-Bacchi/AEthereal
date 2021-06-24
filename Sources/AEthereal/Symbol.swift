//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

public struct Symbol {
    
    public let code: AE4
    public let type: AE4.AEType
    
    public init(code: AE4, type: AE4.AEType) {
        self.code = code
        self.type = type
    }
    
}

// MARK: AECodable
extension Symbol: AECodable {
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        encodeAEDescriptor()
    }
    
    public func encodeAEDescriptor() -> AEDescriptor {
        AEDescriptor(type: type, code: code)
    }
    
    public init(from descriptor: AEDescriptor) {
        self.code = descriptor.enumCodeValue
        self.type = AE4.AEType(rawValue: descriptor.descriptorType)
    }
    
    public init(from descriptor: AEDescriptor, app: App) {
        self.init(from: descriptor)
    }
    
}

// MARK: Hashable
extension Symbol: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    public static func ==(lhs: Symbol, rhs: Symbol) -> Bool {
        // note: operands are not required to be the same subclass as this compares for AE equality only, e.g.:
        //
        //    TED.document == AESymbol(code: "docu") -> true
        //
        // note: AE types are also ignored on the [reasonable] assumption that any differences in descriptor type (e.g. typeType vs typeProperty) are irrelevant as apps will only care about the code itself
        lhs.code == rhs.code
    }
    
}
