//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

/// An AppleEvent object model query.
public indirect enum Query: Codable {
    
    case rootSpecifier(RootSpecifier)
    case objectSpecifier(ObjectSpecifier)
    case insertionSpecifier(InsertionSpecifier)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .rootSpecifier(rootSpecifier):
            try container.encode(rootSpecifier)
        case let .objectSpecifier(objectSpecifier):
            try container.encode(objectSpecifier)
        case let .insertionSpecifier(insertionSpecifier):
            try container.encode(insertionSpecifier)
        }
    }
    
    public init(from decoder: Decoder) throws {
        guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Can only decode a query from an AEDescriptor"))
        }
        switch descriptor.type {
        case .objectSpecifier:
            self = .objectSpecifier(try ObjectSpecifier(from: decoder))
        case .insertionLoc:
            self = .insertionSpecifier(try InsertionSpecifier(from: decoder))
        default:
            self = .rootSpecifier(try RootSpecifier(from: decoder))
        }
    }
    
}
    
public struct ObjectSpecifier: Codable, AETyped {
    
    public init(parent: Query, wantType: AE4.AEType, selectorForm: IndexForm) {
        self.parent = parent
        self.wantType = wantType
        self.selectorForm = selectorForm
    }
    
    public var parent: Query
    public var wantType: AE4.AEType
    public var selectorForm: IndexForm
    
    public indirect enum IndexForm {
        
        case property(AE4.AEEnum)
        case userProperty(String)
        case name(String)
        case id(Encodable)
        case index(Int)
        case absolute(AE4.AbsoluteOrdinal)
        case relative(AE4.RelativeOrdinal)
        case range(RangeSelector)
        case test(TestClause)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parent, forKey: .container)
        try container.encode(wantType, forKey: .wantType)
        switch selectorForm {
        case let .property(property):
            try container.encode(AE4.IndexForm.propertyID, forKey: .keyForm)
            try container.encode(property, forKey: .keyData)
        case let .userProperty(userProperty):
            try container.encode(AE4.IndexForm.userPropertyID, forKey: .keyForm)
            try container.encode(userProperty, forKey: .keyData)
        case let .name(name):
            try container.encode(AE4.IndexForm.name, forKey: .keyForm)
            try container.encode(name, forKey: .keyData)
        case let .id(id):
            try container.encode(AE4.IndexForm.uniqueID, forKey: .keyForm)
            try id.encode(to: &container, forKey: .keyData)
        case let .index(index):
            try container.encode(AE4.IndexForm.absolutePosition, forKey: .keyForm)
            try container.encode(index, forKey: .keyData)
        case let .absolute(absolute):
            try container.encode(AE4.IndexForm.absolutePosition, forKey: .keyForm)
            try container.encode(absolute, forKey: .keyData)
        case let .relative(relative):
            try container.encode(AE4.IndexForm.relativePosition, forKey: .keyForm)
            try container.encode(relative, forKey: .keyData)
        case let .range(range):
            try container.encode(AE4.IndexForm.range, forKey: .keyForm)
            try container.encode(range, forKey: .keyData)
        case let .test(test):
            try container.encode(AE4.IndexForm.test, forKey: .keyForm)
            try container.encode(test, forKey: .keyData)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parent = try container.decode(Query.self, forKey: .container)
        wantType = try container.decode(AE4.AEType.self, forKey: .wantType)
        switch try container.decode(AE4.IndexForm.self, forKey: .keyForm) {
        case .propertyID:
            selectorForm = .property(try container.decode(AE4.AEEnum.self, forKey: .keyData))
        case .userPropertyID:
            selectorForm = .userProperty(try container.decode(String.self, forKey: .keyData))
        case .name:
            selectorForm = .name(try container.decode(String.self, forKey: .keyData))
        case .uniqueID:
            guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Can only decode an id-based object specifier from an AEDescriptor"))
            }
            selectorForm = .id(descriptor[AE4.ObjectSpecifierKeywords.keyData])
        case .absolutePosition:
            if let absolute = try? container.decode(AE4.AbsoluteOrdinal.self, forKey: .keyData) {
                selectorForm = .absolute(absolute)
            } else {
                selectorForm = .index(try container.decode(Int.self, forKey: .keyData))
            }
        case .relativePosition:
            selectorForm = .relative(try container.decode(AE4.RelativeOrdinal.self, forKey: .keyData))
        case .range:
            selectorForm = .range(try container.decode(RangeSelector.self, forKey: .keyData))
        case .test:
            selectorForm = .test(try container.decode(TestClause.self, forKey: .keyData))
        }
    }
    
    public var aeType: AE4.AEType {
        .objectSpecifier
    }
    
    private enum CodingKeys: AE4, AE4CodingKey {
        
        case container = 0x66726f6d
        case wantType = 0x77616e74
        case keyForm = 0x666f726d
        case keyData = 0x73656c64
        
        static var recordAEType: AE4.AEType {
            .objectSpecifier
        }
        
    }
    
    public struct RangeSelector: Codable, AETyped {
        
        // These can obviously be anything Codable when constructed manually,
        // but when decoded from AEDescriptor, these will be AEDescriptors:
        public let start: Encodable
        public let stop: Encodable

        public init(start: Encodable, stop: Encodable) {
            self.start = start
            self.stop = stop
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try start.encode(to: &container, forKey: .start)
            try stop.encode(to: &container, forKey: .stop)
        }
        
        public init(from decoder: Decoder) throws {
            guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Can only decode a range selector from an AEDescriptor"))
            }
            guard
                let start = descriptor[CodingKeys.start.rawValue],
                let stop = descriptor[CodingKeys.stop.rawValue]
            else {
                throw DecodingError.valueNotFound(AEDescriptor.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Range selector requires both start and stop descriptors"))
            }
            self.init(start: start, stop: stop)
        }
        
        public var aeType: AE4.AEType {
            .rangeDescriptor
        }
        
        private enum CodingKeys: AE4, AE4CodingKey {
            
            case start = 0x73746172
            case stop = 0x73746f70
            
        }
        
    }
    
    public indirect enum TestClause: Codable, AETyped {
        
        case comparison(operator: AE4.Comparison, lhs: Encodable, rhs: Encodable)
        case logicalBinary(operator: AE4.LogicalOperator, lhs: TestClause, rhs: TestClause)
        case logicalUnary(operator: AE4.LogicalOperator, operand: TestClause)
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .comparison(`operator`, lhs, rhs):
                try container.encode(`operator`, forKey: .comparisonOperator)
                try lhs.encode(to: &container, forKey: .comparisonFirstObject)
                try rhs.encode(to: &container, forKey: .comparisonSecondObject)
            case let .logicalBinary(`operator`, lhs, rhs):
                try container.encode(`operator`, forKey: .logicalOperator)
                try container.encode([lhs, rhs], forKey: .logicalTerms)
            case let .logicalUnary(`operator`, operand):
                try container.encode(`operator`, forKey: .logicalOperator)
                try container.encode([operand], forKey: .logicalTerms)
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if container.contains(.comparisonOperator) {
                guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Can only decode a test clause from an AEDescriptor"))
                }
                guard
                    let lhs = descriptor[CodingKeys.comparisonFirstObject.rawValue],
                    let rhs = descriptor[CodingKeys.comparisonSecondObject.rawValue]
                else {
                    throw DecodingError.valueNotFound(AEDescriptor.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Comparison test clause requres both operands"))
                }
                self = .comparison(
                    operator: try container.decode(AE4.Comparison.self, forKey: .comparisonOperator),
                    lhs: lhs,
                    rhs: rhs
                )
            } else if container.contains(.logicalOperator) {
                let `operator` = try container.decode(AE4.LogicalOperator.self, forKey: .logicalOperator)
                let terms = try container.decode([AEDescriptor].self, forKey: .logicalTerms)
                switch terms.count {
                case 1:
                    self = .logicalUnary(operator: `operator`, operand: try AEDecoder.decode(terms[0]))
                case 2:
                    self = .logicalBinary(operator: `operator`, lhs: try AEDecoder.decode(terms[0]), rhs: try AEDecoder.decode(terms[1]))
                default:
                    throw DecodingError.dataCorruptedError(forKey: .logicalTerms, in: container, debugDescription: "\(terms) has wrong number of logical terms")
                }
            } else {
                throw DecodingError.typeMismatch(TestClause.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(container.allKeys) does not contain a test clause operator"))
            }
        }
        
        public var aeType: AE4.AEType {
            switch self {
            case .comparison:
                return .compDescriptor
            case .logicalBinary, .logicalUnary:
                return .logicalDescriptor
            }
        }
        
        private enum CodingKeys: AE4, AE4CodingKey {
            
            case comparisonOperator = 0x72656c6f
            case comparisonFirstObject = 0x6f626a31
            case comparisonSecondObject = 0x6f626a32
            
            case logicalOperator = 0x6c6f6763
            case logicalTerms = 0x7465726d
            
        }
        
    }
    
}

public struct InsertionSpecifier: Codable, AETyped {
    
    public var parent: Query
    public var insertionLocation: AE4.InsertionLocation
    
    public init(parent: Query, insertionLocation: AE4.InsertionLocation) {
        self.parent = parent
        self.insertionLocation = insertionLocation
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try parent.encode(to: &container, forKey: .parent)
        try insertionLocation.encode(to: &container, forKey: .insertionLocation)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            parent: try container.decode(Query.self, forKey: .parent),
            insertionLocation: try container.decode(AE4.InsertionLocation.self, forKey: .insertionLocation)
        )
    }
    
    private enum CodingKeys: AE4, AE4CodingKey {
        
        case parent = 0x6B6F626A
        case insertionLocation = 0x6B706F73
        
    }
    
    public var aeType: AE4.AEType {
        .insertionLoc
    }
    
}

public enum RootSpecifier: Codable {
    
    /// Root of all absolute object specifiers.
    /// e.g., `document 1 of «application»`.
    case application
    /// Root of an object specifier specifying the start or end of a range of
    /// elements in a by-range specifier.
    /// e.g., `folders (folder 2 of «container») thru (folder -1 of «container»)`.
    case container
    /// Root of an object specifier specifying an element whose state is being
    /// compared in a by-test specifier.
    /// e.g., `every track where (rating of «specimen» > 50)`.
    case specimen
    /// Root of an object specifier that descends from a descriptor object.
    /// e.g., `item 1 of {1,2,3}`.
    /// (These sorts of descriptors are effectively exclusively generated
    /// by AppleScript).
    case object(AEDescriptor)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .application:
            try container.encode(AEDescriptor.appRoot)
        case .container:
            try container.encode(AEDescriptor.containerRoot)
        case .specimen:
            try container.encode(AEDescriptor.specimenRoot)
        case let .object(descriptor):
            try container.encode(descriptor)
        }
    }
    
    public init(from decoder: Decoder) throws {
        guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
            self = .application
            return
        }
        switch descriptor.type {
        case .null:
            self = .application
        case .currentContainer:
            self = .container
        case .objectBeingExamined:
            self = .specimen
        default:
            self = .object(descriptor)
        }
    }
    
}
