//  Originally written by hhas.
//  See README.md for licensing information.

import AppKit

/******************************************************************************/
// App converts values between Swift and AE types, holds target process information, and provides methods for sending Apple events

public final class App {
    
    public static var generic = App()
    
    // Compatibility flags; these make SwiftAutomation more closely mimic certain AppleScript behaviors that may be expected by a few older apps
    
    public var isInt64Compatible: Bool = true // While App.encode() always encodes integers within the SInt32.min...SInt32.max range as typeSInt32, if the isInt64Compatible flag is true then it will use typeUInt32/typeSInt64/typeUInt64 for integers outside of that range. Some older Carbon-based apps (e.g. MS Excel) may not accept these larger integer types, so set this flag false when working with those apps to encode large integers as Doubles instead, effectively emulating AppleScript which uses SInt32 and Double only. (Caution: as in AppleScript, integers beyond ±2**52 will lose precision when converted to Double.)
    
    public init(target: AETarget = .none) {
        self.target = target
    }
    
    // the following properties are mainly for internal use, but SpecifierFormatter may also get them when rendering app roots
    public let target: AETarget
    
    var _targetDescriptor: AEDescriptor? = nil // targetDescriptor() creates an AEAddressDesc for the target process when dispatching first Apple event, caching it here for subsequent reuse
    
    var _transactionID: AETransactionID = .any
    var _transactionLock = NSLock()
    
}

// MARK: Specifier roots
extension App {
    
    public var application: RootSpecifier {
        return RootSpecifier(.application, app: self)
    }
    
    public var container: RootSpecifier {
        return RootSpecifier(.container, app: self)
    }
    
    public var specimen: RootSpecifier {
        return RootSpecifier(.specimen, app: self)
    }
    
}

// MARK: Descriptor encoding
extension App {
    
    public func encode(_ value: Any) throws -> AEDescriptor {
        switch value {
        case let val as AEEncodable:
            return try val.encodeAEDescriptor(self)
        
        case let val as Int8:
            return AEDescriptor(int32: Int32(val))
        case let val as UInt8:
            return AEDescriptor(int32: Int32(val))
        case let val as Int16:
            return AEDescriptor(int32: Int32(val))
        case let val as UInt16:
            return AEDescriptor(int32: Int32(val))
        case let val as Error:
            throw val // if value is ErrorType, rethrow it as-is; e.g. see ObjectSpecifier.decodeParentSpecifiers(), which needs to report [rare] errors but can't throw itself; this should allow APIs that can't raise errors directly (e.g. specifier constructors) to have those errors raised if/when used in commands (which can throw)
        default:
            break
        }
        throw EncodeError(object: value)
    }
    
}

// MARK: Descriptor decoding
extension App {
    
    public func decode(_ desc: AEDescriptor) throws -> AEValue {
        switch desc.type {
        case .null:
            return .rootSpecifier(self.application)
        case .currentContainer:
            return .rootSpecifier(self.container)
        case .objectBeingExamined:
            return .rootSpecifier(self.specimen)
        case .objectSpecifier:
            return .objectSpecifier(try self.decodeAsObjectSpecifier(desc))
        case .insertionLoc:
            return .insertionSpecifier(try self.decodeAsInsertionLoc(desc))
        
        case .compDescriptor:
            return .comparisonTest(try self.decodeAsComparisonDescriptor(desc))
        case .logicalDescriptor:
            return .logicalTest(try self.decodeAsLogicalDescriptor(desc))
        
        case .type, .enumerated, .property, .keyword, .absoluteOrdinal:
            return desc.isMissingValue ? .missingValue : .symbol(Symbol(from: desc, app: self))
        
        case .true, .false, .boolean:
            return .bool(try Bool(from: desc, app: self))
        case .sInt32, .sInt16:
            return .int32(try Int32(from: desc, app: self))
        case .sInt64:
            return .int64(try Int64(from: desc, app: self))
        case .uInt64, .uInt32, .uInt16:
            return .uint64(try UInt64(from: desc, app: self))
        case .ieee64BitFloatingPoint, .ieee32BitFloatingPoint:
            return .double(try Double(from: desc, app: self))
        case ._128BitFloatingPoint:
            guard let double = desc.coerce(to: .ieee64BitFloatingPoint) else {
                throw DecodeError(descriptor: desc, type: Any.self, message: "Can't coerce 128-bit float to double.")
            }
            return .double(try Double(from: double, app: self))
        case .text, .intlText, .utf8Text, .utf16ExternalRepresentation, .styledText, .unicodeText, .version:
            return .string(try String(from: desc, app: self))
        case .longDateTime:
            return .date(try Date(from: desc, app: self))
            
        case .list:
            return .list(try [AEValue](from: desc, app: self))
        case .record:
            return .record(try [AE4 : AEValue](from: desc, app: self))
            
        case .alias, .bookmarkData, .fileURL, .fsRef:
            return .fileURL(try URL(from: desc, app: self))
            
        case .qdPoint:
            return .point(try CGPoint(from: desc, app: self))
        case .qdRectangle:
            return .rect(try CGRect(from: desc, app: self))
        case .rgbColor:
            return .color(try RGBColor(from: desc, app: self))
            
        // note: while there are also several AEAddressDesc types used to identify applications, these are very rarely used as command results (e.g. the `choose application` OSAX) and there's little point decoding them anway as the only type they can automatically be mapped to is AEApplication, which has only minimal functionality anyway. Also unsupported are unit types as they only cover a handful of measurement types and in practice aren't really used for anything except measurement conversions in AppleScript.
        default:
            if desc.isRecordDescriptor {
                return .record(try [AE4 : AEValue](from: desc, app: self))
            }
            return .descriptor(desc)
        }
    }
    
    public func decodeQuery(_ desc: AEDescriptor) throws -> Query {
        switch try decode(desc) {
        case let .rootSpecifier(query as Query),
             let .objectSpecifier(query as Query),
             let .insertionSpecifier(query as Query):
            return query
        default:
            throw DecodeError(descriptor: desc, type: Query.self)
        }
    }
    
    public func decodeTestClauseList(_ desc: AEDescriptor) throws -> [TestClause] {
        switch try decode(desc) {
        case let .comparisonTest(testClause as TestClause),
             let .logicalTest(testClause as TestClause):
            return [testClause]
        case let .list(list):
            return try list.map { decoded in
                switch decoded {
                case let .comparisonTest(testClause as TestClause),
                     let .logicalTest(testClause as TestClause):
                    return testClause
                default:
                    throw DecodeError(descriptor: desc, type: TestClause.self)
                }
            }
        default:
            throw DecodeError(descriptor: desc, type: [TestClause].self)
        }
    }
    
}

private let _absoluteOrdinalCodes: Set<AE4> = Set(AE4.AbsoluteOrdinal.allCases.map { $0.rawValue })
private let _relativeOrdinalCodes: Set<AE4> = Set(AE4.RelativeOrdinal.allCases.map { $0.rawValue })

private let _comparisonOperatorCodes: Set<AE4> = Set(AE4.Comparison.allCases.map { $0.rawValue })
private let _logicalOperatorCodes: Set<AE4> = Set(AE4.LogicalOperator.allCases.map { $0.rawValue })

// MARK: Decoding helpers
extension App {
    
    func decodeAsInsertionLoc(_ desc: AEDescriptor) throws -> InsertionSpecifier {
        guard
            let _ = desc[AE4.InsertionSpecifierKeywords.object], // only used to check InsertionLoc record is correctly formed
            let insertionLocationDesc = desc[AE4.InsertionSpecifierKeywords.position],
            let insertionLocation = AE4.InsertionLocation(rawValue: insertionLocationDesc.enumCodeValue)
        else {
            throw DecodeError(descriptor: desc, type: InsertionSpecifier.self, message: "Can't decode malformed insertion specifier.")
        }
        return InsertionSpecifier(insertionLocation: insertionLocation, parentQuery: try decodeQuery(desc), app: self)
    }
    
    func decodeAsObjectSpecifier(_ desc: AEDescriptor) throws -> SingleObjectSpecifier {
        guard
            let parentDesc = desc[AE4.ObjectSpecifierKeywords.container],
            let wantType = desc[AE4.ObjectSpecifierKeywords.desiredClass],
            let selectorFormDesc = desc[AE4.ObjectSpecifierKeywords.keyForm],
            let selectorForm = AE4.IndexForm(rawValue: selectorFormDesc.enumCodeValue),
            let selectorDesc = desc[AE4.ObjectSpecifierKeywords.keyData]
        else {
            throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self, message: "Can't decode malformed object specifier.")
        }
        do {
            var selectorData = try decode(selectorDesc)
            var objectSpecifierClass = SingleObjectSpecifier.self // most reference forms describe one-to-one relationships
            switch selectorForm {
            case .propertyID:
                if ![.type, .property].contains(selectorDesc.type) {
                    throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self, message: "Can't decode malformed object specifier.")
                }
            case .relativePosition:
                if !(selectorDesc.type == .enumerated && _relativeOrdinalCodes.contains(selectorDesc.enumCodeValue)) {
                    throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self,
                                      message: "Can't decode malformed object specifier.")
                }
            case .absolutePosition:
                if
                    selectorDesc.type == .enumerated,
                    selectorDesc.enumCodeValue == AE4.AbsoluteOrdinal.all.rawValue
                {
                    objectSpecifierClass = MultipleObjectSpecifier.self
                }
            case .range:
                objectSpecifierClass = MultipleObjectSpecifier.self
                selectorData = .range(try RangeSelector(from: desc, wantType: AE4.AEType(rawValue: wantType.typeCodeValue), app: self))
            case .test:
                objectSpecifierClass = MultipleObjectSpecifier.self
                if !(selectorData is Query) {
                    throw DecodeError(descriptor: selectorDesc, type: Query.self, message: "Malformed selector in by-test specifier.")
                }
            case .name, .uniqueID, .userPropertyID:
                break
            }
            return objectSpecifierClass.init(
                wantType: AE4.AEType(rawValue: wantType.typeCodeValue),
                selectorForm: selectorForm,
                selectorData: selectorData,
                parentQuery: try decodeQuery(parentDesc),
                app: self
            )
        } catch {
            throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self, message: "Can't decode object specifier's selector data.", cause: error)
        }
    }
    
    func decodeAsComparisonDescriptor(_ desc: AEDescriptor) throws -> ComparisonTest {
        if
            let operatorTypeDesc = desc.forKeyword(AE4.TestPredicateKeywords.comparisonOperator),
            let operatorType = AE4.Comparison(rawValue: operatorTypeDesc.enumCodeValue),
            let operand1Desc = desc.forKeyword(AE4.TestPredicateKeywords.firstObject),
            let operand2Desc = desc.forKeyword(AE4.TestPredicateKeywords.secondObject),
            !_comparisonOperatorCodes.contains(operatorType.rawValue)
        {
                // don't bother with dedicated error reporting here as malformed operand descs that cause the following decode calls to fail are unlikely in practice, and will still be caught and reported further up the call chain anyway
                let operand1 = try decode(operand1Desc)
                let operand2 = try decode(operand2Desc)
                if case let .objectSpecifier(op1) = operand1 {
                    return ComparisonTest(operatorType: operatorType, operand1: op1, operand2: operand2, app: self)
                } else if
                    operatorType == .contains,
                    case let .objectSpecifier(op2) = operand2
                {
                    return ComparisonTest(operatorType: .isIn, operand1: op2, operand2: operand1, app: self)
                }
        }
        throw DecodeError(descriptor: desc, type: TestClause.self, message: "Can't decode comparison test: malformed descriptor.")
    }
    
    func decodeAsLogicalDescriptor(_ desc: AEDescriptor) throws -> LogicalTest {
        if
            let operatorTypeDesc = desc.forKeyword(AE4.TestPredicateKeywords.logicalOperator),
            let operatorType = AE4.LogicalOperator(rawValue: operatorTypeDesc.enumCodeValue),
            let operandsDesc = desc.forKeyword(AE4.TestPredicateKeywords.object),
            !_logicalOperatorCodes.contains(operatorType.rawValue)
        {
            return LogicalTest(operatorType: operatorType, operands: try decodeTestClauseList(operandsDesc), app: self)
        }
        throw DecodeError(descriptor: desc, type: TestClause.self, message: "Can't decode logical test: malformed descriptor.")
    }
    
}
