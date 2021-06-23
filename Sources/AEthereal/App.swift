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
    
    var _targetDescriptor: NSAppleEventDescriptor? = nil // targetDescriptor() creates an AEAddressDesc for the target process when dispatching first Apple event, caching it here for subsequent reuse
    
    var _transactionID: AETransactionID = AE4.anyTransactionID
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

// Swift's NSNumber bridging is hopelessly ambiguous, so it's not enough to ask if `value is Bool/Int/Double` or to try casting it to Bool/Int/Double, as these ALWAYS succeed for ALL NSNumbers, regardless of what type the NSNumber actually represents, e.g. `NSNumber(value:true) is Bool` returns `true` as expected, but `NSNumber(value:2) is Bool` and `NSNumber(value:3.3) is Bool` return `true` too! Therefore, the only way to determine if `value` is a Swift Bool/Int/Double is to first eliminate the possibility that it's an NSNumber by testing for that first. This is further complicated by NSNumber being a class cluster, not a concrete class, so we can't just test if `type(of: value) == NSNumber.self`; we have to extract the underlying __NSCF… classes and test against those. This makes some assumptions based on established NSNumber implementation; if that implementation should change in future (either in Cocoa itself or in the way that Swift maps it) then these assumptions may break, resulting in incorrect/broken behavior in the encode() method below.
private let _NSBooleanType = type(of: NSNumber(value: true)) // this assumes Cocoa always represents true/false as __NSCFBoolean
private let _NSNumberType = type(of: NSNumber(value: 1)) // this assumes Cocoa always represents all integer and FP numbers as __NSCFNumber

// MARK: Descriptor encoding
extension App {
    
    public func encode(_ value: Any) throws -> NSAppleEventDescriptor {
        // note: Swift's Bool/Int/Double<->NSNumber bridging sucks, so NSNumber instances require special processing to ensure the underlying value's exact type (Bool/Int/Double/etc) isn't lost in translation
        if type(of: value) == _NSBooleanType { // test for NSNumber(value:true/false)
            // important: 
            // - the first test assumes NSNumber class cluster always returns an instance of __NSCFBooleanType (or at least something that can be distinguished from all other NSNumbers)
            // - `value is Bool/Int/Double` always returns true for any NSNumber, so must not be used; however, checking for BooleanType returns true only for Bool (or other Swift types that implement BooleanType protocol) so should be safe
            return NSAppleEventDescriptor(boolean: value as! Bool)
        } else if type(of: value) == _NSNumberType { // test for any other NSNumber (but not Swift numeric types as those will be dealt with below)
            let numberObj = value as! NSNumber
            switch numberObj.objCType.pointee as Int8 {
            case 98, 99, 67, 115, 83, 105: // (b, c, C, s, S, i) anything that will fit into SInt32 is encoded as typeSInt32 for compatibility
                return NSAppleEventDescriptor(int32: numberObj.int32Value)
            case 73: // (I) UInt32
                var val = numberObj.uint32Value
                if val <= UInt32(Int32.max) {
                    return NSAppleEventDescriptor(int32: Int32(val))
                } else if self.isInt64Compatible {
                    return NSAppleEventDescriptor(descriptorType: typeUInt32, bytes: &val, length: MemoryLayout<UInt32>.size)!
                } // else encode as double
            case 108, 113: // (l, q) SInt64
                var val = numberObj.int64Value
                if val >= Int64(Int32.min) && val <= Int64(Int32.max) {
                    return NSAppleEventDescriptor(int32: Int32(val))
                } else if self.isInt64Compatible {
                    return NSAppleEventDescriptor(descriptorType: typeSInt64, bytes: &val, length: MemoryLayout<Int64>.size)!
                } // else encode as double, possibly with some loss of precision
            case 76, 81: // (L, Q) UInt64
                var val = numberObj.uint64Value
                if val <= UInt64(Int32.max) {
                    return NSAppleEventDescriptor(int32: Int32(val))
                } else if self.isInt64Compatible {
                    return NSAppleEventDescriptor(descriptorType: typeUInt64, bytes: &val, length: MemoryLayout<UInt64>.size)!
                } // else encode as double, possibly with some loss of precision
            default:
                ()
            }
            return NSAppleEventDescriptor(double: numberObj.doubleValue)
        }
        switch value {
        case let val as AEEncodable:
            return try val.encodeAEDescriptor(self)
        case let obj as NSAppleEventDescriptor:
            return obj
        case var val as Int:
            // Note: to maximize application compatibility, always preferentially encode integers as typeSInt32, as that's the traditional integer type recognized by all apps. (In theory, encoding as typeSInt64 shouldn't be a problem as apps should coerce to whatever type they actually require before decoding, but not-so-well-designed Carbon apps sometimes explicitly typecheck instead, so will fail if the descriptor isn't the assumed typeSInt32.)
            if Int(Int32.min) <= val && val <= Int(Int32.max) {
                return NSAppleEventDescriptor(int32: Int32(val))
            } else if self.isInt64Compatible {
                return NSAppleEventDescriptor(descriptorType: AE4.Types.sInt64, bytes: &val, length: MemoryLayout<Int>.size)!
            } else {
                return NSAppleEventDescriptor(double: Double(val)) // caution: may be some loss of precision
            }
        case let val as Double:
            return NSAppleEventDescriptor(double: val)
        case let val as String:
            return NSAppleEventDescriptor(string: val)
        case let obj as Date:
          return NSAppleEventDescriptor(date: obj)
        case let obj as URL:
            if obj.isFileURL {
                return NSAppleEventDescriptor(fileURL: obj)
            }
        
        case var val as UInt:
            if val <= UInt(Int32.max) {
                return NSAppleEventDescriptor(int32: Int32(val))
            } else if self.isInt64Compatible {
                return NSAppleEventDescriptor(descriptorType: AE4.Types.uInt32, bytes: &val, length: MemoryLayout<UInt>.size)!
            } else {
                return NSAppleEventDescriptor(double: Double(val))
            }
        case let val as Int8:
            return NSAppleEventDescriptor(int32: Int32(val))
        case let val as UInt8:
            return NSAppleEventDescriptor(int32: Int32(val))
        case let val as Int16:
            return NSAppleEventDescriptor(int32: Int32(val))
        case let val as UInt16:
            return NSAppleEventDescriptor(int32: Int32(val))
        case let val as Int32:
            return NSAppleEventDescriptor(int32: Int32(val))
        case var val as UInt32:
            if val <= UInt32(Int32.max) {
                return NSAppleEventDescriptor(int32: Int32(val))
            } else if self.isInt64Compatible {
                return NSAppleEventDescriptor(descriptorType: AE4.Types.uInt32, bytes: &val, length: MemoryLayout<UInt32>.size)!
            } else {
                return NSAppleEventDescriptor(double: Double(val))
            }
        case var val as Int64:
            if val >= Int64(Int32.min) && val <= Int64(Int32.max) {
                return NSAppleEventDescriptor(int32: Int32(val))
            } else if self.isInt64Compatible {
                return NSAppleEventDescriptor(descriptorType: AE4.Types.sInt64, bytes: &val, length: MemoryLayout<Int64>.size)!
            } else {
                return NSAppleEventDescriptor(double: Double(val)) // caution: may be some loss of precision
            }
        case var val as UInt64:
            if val <= UInt64(Int32.max) {
                return NSAppleEventDescriptor(int32: Int32(val))
            } else if self.isInt64Compatible {
                return NSAppleEventDescriptor(descriptorType: AE4.Types.uInt64, bytes: &val, length: MemoryLayout<UInt64>.size)!
            } else {
                return NSAppleEventDescriptor(double: Double(val)) // caution: may be some loss of precision
            }
        case let val as Float:
            return NSAppleEventDescriptor(double: Double(val))
        case let val as Bool: // hopefully Swift hasn't [mis]cast `true` or `false` in one of the above cases
            return NSAppleEventDescriptor(boolean: val)
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
    
    public func decode(_ desc: NSAppleEventDescriptor) throws -> AEValue {
        switch desc.descriptorType {
        case AE4.Types.null:
            return .rootSpecifier(self.application)
        case AE4.Types.currentContainer:
            return .rootSpecifier(self.container)
        case AE4.Types.objectBeingExamined:
            return .rootSpecifier(self.specimen)
        case AE4.Types.objectSpecifier:
            return .objectSpecifier(try self.decodeAsObjectSpecifier(desc))
        case AE4.Types.insertionLoc:
            return .insertionSpecifier(try self.decodeAsInsertionLoc(desc))
        
        case AE4.Types.compDescriptor:
            return .comparisonTest(try self.decodeAsComparisonDescriptor(desc))
        case AE4.Types.logicalDescriptor:
            return .logicalTest(try self.decodeAsLogicalDescriptor(desc))
        
        case AE4.Types.type, AE4.Types.enumerated, AE4.Types.property, AE4.Types.keyword:
            return isMissingValue(desc) ? .missingValue : .symbol(Symbol(code: desc.typeCodeValue, type: desc.descriptorType))
        
        case AE4.Types.true, AE4.Types.false, AE4.Types.boolean:
            return .bool(desc.booleanValue)
        case AE4.Types.sInt32, AE4.Types.sInt16:
            return .int32(desc.int32Value)
        case AE4.Types.sInt64:
            return .int64(self.decodeAsInt64(desc)!)
        case AE4.Types.uInt64, AE4.Types.uInt32, AE4.Types.uInt16:
            return .uint64(self.decodeAsUInt64(desc)!)
        case AE4.Types.ieee64BitFloatingPoint, AE4.Types.ieee32BitFloatingPoint:
            return .double(desc.doubleValue)
        case AE4.Types._128BitFloatingPoint:
            guard let doubleDesc = desc.coerce(toDescriptorType: AE4.Types.ieee64BitFloatingPoint) else {
                throw DecodeError(descriptor: desc, type: Any.self, message: "Can't coerce 128-bit float to double.")
            }
            return .double(doubleDesc.doubleValue)
        case AE4.Types.text, AE4.Types.intlText, AE4.Types.utf8Text, AE4.Types.utf16ExternalRepresentation, AE4.Types.styledText, AE4.Types.unicodeText, AE4.Types.version:
            guard let string = desc.stringValue else { // this should never fail unless the AEDesc contains mis-encoded text data (e.g. claims to be typeUTF8Text but contains non-UTF8 byte sequences)
                throw DecodeError(descriptor: desc, type: Any.self, message: "Corrupt string descriptor.")
            }
            return .string(string)
        case AE4.Types.longDateTime:
            guard let date = desc.dateValue else { // this should never fail unless the AEDesc contains bad data
                throw DecodeError(descriptor: desc, type: Any.self, message: "Corrupt descriptor.")
            }
            return .date(date)
        
        case AE4.Types.list:
            return .list(try Array(from: desc, app: self) as [AEValue])
        case AE4.Types.record:
            return .record(try Dictionary(from: desc, app: self) as [Symbol : AEValue])
        
        case AE4.Types.alias, AE4.Types.bookmarkData, AE4.Types.fileURL, AE4.Types.fsRef:
            guard let fileURL = desc.fileURLValue else { // ditto
                throw DecodeError(descriptor: desc, type: Any.self, message: "Corrupt descriptor.")
            }
            return .fileURL(fileURL)
        
        case AE4.Types.qdPoint:
            return .point(try CGPoint(from: desc, app: self))
        case AE4.Types.qdRectangle:
            return .rect(try CGRect(from: desc, app: self))
        case AE4.Types.rgbColor:
            return .color(try RGBColor(from: desc, app: self))
        
        // note: while there are also several AEAddressDesc types used to identify applications, these are very rarely used as command results (e.g. the `choose application` OSAX) and there's little point decoding them anway as the only type they can automatically be mapped to is AEApplication, which has only minimal functionality anyway. Also unsupported are unit types as they only cover a handful of measurement types and in practice aren't really used for anything except measurement conversions in AppleScript.
        default:
            if desc.isRecordDescriptor {
                return .record(try Dictionary(from: desc, app: self) as [Symbol : AEValue])
            }
            return .descriptor(desc)
        }
    }
    
    public func decodeQuery(_ desc: NSAppleEventDescriptor) throws -> Query {
        switch try decode(desc) {
        case let .rootSpecifier(query as Query),
             let .objectSpecifier(query as Query),
             let .insertionSpecifier(query as Query):
            return query
        default:
            throw DecodeError(descriptor: desc, type: Query.self)
        }
    }
    
    public func decodeTestClauseList(_ desc: NSAppleEventDescriptor) throws -> [TestClause] {
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

private let _absoluteOrdinalCodes: Set<OSType> = Set(AE4.AbsoluteOrdinal.allCases.map { $0.rawValue })
private let _relativeOrdinalCodes: Set<OSType> = Set(AE4.RelativeOrdinal.allCases.map { $0.rawValue })

private let _comparisonOperatorCodes: Set<OSType> = Set(AE4.Comparison.allCases.map { $0.rawValue } + AE4.Containment.allCases.map { $0.rawValue } + [AE4.notEquals, AE4.isIn])
private let _logicalOperatorCodes: Set<OSType> = Set(AE4.LogicalOperator.allCases.map { $0.rawValue })

// MARK: Decoding helpers
extension App {

    private func decodeAsInt64(_ desc: NSAppleEventDescriptor) -> Int64? {
        // coerce the descriptor (whatever it is - typeSInt16, typeUInt32, typeUnicodeText, etc.) to typeSIn64 (hoping the Apple Event Manager has remembered to install TYPE-to-SInt64 coercion handlers for all these types too), and decode as Int[64]
        if let intDesc = desc.coerce(toDescriptorType: AE4.Types.sInt64) {
            var result: Int64 = 0
            (intDesc.data as NSData).getBytes(&result, length: MemoryLayout<Int64>.size)
            return result
        } else {
            return nil
        }
    }

    private func decodeAsUInt64(_ desc: NSAppleEventDescriptor) -> UInt64? {
        // as above, but for unsigned ints
        if let intDesc = desc.coerce(toDescriptorType: AE4.Types.uInt64) {
            var result: UInt64 = 0
            (intDesc.data as NSData).getBytes(&result, length: MemoryLayout<UInt64>.size)
            return result
        } else {
            return nil
        }
    }
    
    func decodeAsInsertionLoc(_ desc: NSAppleEventDescriptor) throws -> InsertionSpecifier {
        guard
            let _ = desc.forKeyword(AE4.InsertionSpecifierKeywords.object), // only used to check InsertionLoc record is correctly formed
            let insertionLocation = desc.forKeyword(AE4.InsertionSpecifierKeywords.position)
        else {
                throw DecodeError(descriptor: desc, type: InsertionSpecifier.self, message: "Can't decode malformed insertion specifier.")
        }
        return InsertionSpecifier(insertionLocation: insertionLocation, parentQuery: try decodeQuery(desc), app: self)
    }
    
    func decodeAsObjectSpecifier(_ desc: NSAppleEventDescriptor) throws -> SingleObjectSpecifier {
        guard
            let parentDesc = desc.forKeyword(AE4.ObjectSpecifierKeywords.container),
            let wantType = desc.forKeyword(AE4.ObjectSpecifierKeywords.desiredClass),
            let selectorForm = desc.forKeyword(AE4.ObjectSpecifierKeywords.keyForm),
            let selectorDesc = desc.forKeyword(AE4.ObjectSpecifierKeywords.keyData)
        else {
            throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self, message: "Can't decode malformed object specifier.")
        }
        do { // decode selectorData, unless it's a property code or absolute/relative ordinal (in which case use its 'prop'/'enum' descriptor as-is)
            var selectorData: Any = selectorDesc // the selector won't be decoded if it's a property/relative/absolute ordinal
            var objectSpecifierClass = SingleObjectSpecifier.self // most reference forms describe one-to-one relationships
            switch AE4.IndexForm(rawValue: selectorForm.enumCodeValue) {
            case .propertyID: // property
                if ![AE4.Types.type, AE4.Types.property].contains(selectorDesc.descriptorType) {
                    throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self, message: "Can't decode malformed object specifier.")
                }
            case .relativePosition: // before/after
                if !(selectorDesc.descriptorType == AE4.Types.enumerated && _relativeOrdinalCodes.contains(selectorDesc.enumCodeValue)) {
                    throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self,
                                      message: "Can't decode malformed object specifier.")
                }
            case .absolutePosition: // by-index or first/middle/last/any/all ordinal
                if selectorDesc.descriptorType == AE4.Types.enumerated && _absoluteOrdinalCodes.contains(selectorDesc.enumCodeValue) { // don't decode ordinals
                    if selectorDesc.enumCodeValue == AE4.AbsoluteOrdinal.all.rawValue { // `all` ordinal = one-to-many relationship
                        objectSpecifierClass = MultipleObjectSpecifier.self
                    }
                } else { // decode index (normally Int32, though the by-index form can take any type of selector as long as the app understands it)
                    selectorData = try decode(selectorDesc)
                }
            case .range: // by-range = one-to-many relationship
                objectSpecifierClass = MultipleObjectSpecifier.self
                if selectorDesc.descriptorType != AE4.Types.rangeDescriptor {
                    throw DecodeError(descriptor: selectorDesc, type: RangeSelector.self, message: "Malformed selector in by-range specifier.")
                }
                guard
                    let startDesc = selectorDesc.forKeyword(AE4.RangeSpecifierKeywords.start),
                    let stopDesc = selectorDesc.forKeyword(AE4.RangeSpecifierKeywords.stop)
                else {
                    throw DecodeError(descriptor: selectorDesc, type: RangeSelector.self, message: "Malformed selector in by-range specifier.")
                }
                do {
                    selectorData = RangeSelector(start: try decode(startDesc), stop: try self.decode(stopDesc), wantType: wantType)
                } catch {
                    throw DecodeError(descriptor: selectorDesc, type: RangeSelector.self, message: "Couldn't decode start/stop selector in by-range specifier.")
                }
            case .test: // by-range = one-to-many relationship
                objectSpecifierClass = MultipleObjectSpecifier.self
                selectorData = try decode(selectorDesc)
                if !(selectorData is Query) {
                    throw DecodeError(descriptor: selectorDesc, type: Query.self, message: "Malformed selector in by-test specifier.")
                }
            default: // by-name or by-ID
                selectorData = try decode(selectorDesc)
            }
            return objectSpecifierClass.init(wantType: wantType,
                                             selectorForm: selectorForm, selectorData: selectorData,
                                             parentQuery: try decodeQuery(parentDesc),
                                             app: self)
        } catch {
            throw DecodeError(descriptor: desc, type: SingleObjectSpecifier.self, message: "Can't decode object specifier's selector data.", cause: error)
        }
    }
    
    func decodeAsComparisonDescriptor(_ desc: NSAppleEventDescriptor) throws -> ComparisonTest {
        if
            let operatorType = desc.forKeyword(AE4.TestPredicateKeywords.comparisonOperator),
            let operand1Desc = desc.forKeyword(AE4.TestPredicateKeywords.firstObject),
            let operand2Desc = desc.forKeyword(AE4.TestPredicateKeywords.secondObject),
            !_comparisonOperatorCodes.contains(operatorType.enumCodeValue)
        {
                // don't bother with dedicated error reporting here as malformed operand descs that cause the following decode calls to fail are unlikely in practice, and will still be caught and reported further up the call chain anyway
                let operand1 = try decode(operand1Desc)
                let operand2 = try decode(operand2Desc)
                if case let .objectSpecifier(op1) = operand1 {
                    return ComparisonTest(operatorType: operatorType, operand1: op1, operand2: operand2, app: self)
                } else if
                    operatorType.typeCodeValue == AE4.Containment.contains.rawValue,
                    case let .objectSpecifier(op2) = operand2
                {
                    return ComparisonTest(operatorType: AE4.Descriptors.ContainmentTests.isIn, operand1: op2, operand2: operand1, app: self)
                }
        }
        throw DecodeError(descriptor: desc, type: TestClause.self, message: "Can't decode comparison test: malformed descriptor.")
    }
    
    func decodeAsLogicalDescriptor(_ desc: NSAppleEventDescriptor) throws -> LogicalTest {
        if
            let operatorType = desc.forKeyword(AE4.TestPredicateKeywords.logicalOperator),
            let operandsDesc = desc.forKeyword(AE4.TestPredicateKeywords.object),
            !_logicalOperatorCodes.contains(operatorType.enumCodeValue)
        {
            return LogicalTest(operatorType: operatorType, operands: try decodeTestClauseList(operandsDesc), app: self)
        }
        throw DecodeError(descriptor: desc, type: TestClause.self, message: "Can't decode logical test: malformed descriptor.")
    }
    
}
