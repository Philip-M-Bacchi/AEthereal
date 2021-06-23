//  Originally written by hhas.
//  See README.md for licensing information.

//
//  Swift-AE type conversion and Apple event dispatch
//

import Foundation
import AppKit

// TO DO: get rid of waitReply: arg and just pass .ignoreReply to sendOptions (if ignore/wait/queue option not given, add .waitReply by default)

// NOTE: there are some inbuilt assumptions about `Int` and `UInt` always being 64-bit

let defaultTimeout: TimeInterval = 120 // bug workaround: NSAppleEventDescriptor.sendEvent(options:timeout:) method's support for kAEDefaultTimeout=-1 and kNoTimeOut=-2 flags is buggy <rdar://21477694>, so for now the default timeout is hardcoded here as 120sec (same as in AS)

let defaultIgnoring: Considerations = [.case]

let defaultConsidersIgnoresMask: UInt32 = 0x00010000 // AppleScript ignores case by default

public typealias KeywordParameter = (name: String?, code: OSType, value: Any)

/******************************************************************************/
// App converts values between Swift and AE types, holds target process information, and provides methods for sending Apple events

private let launchOptions: LaunchOptions = DefaultLaunchOptions
private let relaunchMode: RelaunchMode = DefaultRelaunchMode

public final class App {
    
    public static var generic = App()
    
    // Compatibility flags; these make SwiftAutomation more closely mimic certain AppleScript behaviors that may be expected by a few older apps
    
    public var isInt64Compatible: Bool = true // While App.encode() always encodes integers within the SInt32.min...SInt32.max range as typeSInt32, if the isInt64Compatible flag is true then it will use typeUInt32/typeSInt64/typeUInt64 for integers outside of that range. Some older Carbon-based apps (e.g. MS Excel) may not accept these larger integer types, so set this flag false when working with those apps to encode large integers as Doubles instead, effectively emulating AppleScript which uses SInt32 and Double only. (Caution: as in AppleScript, integers beyond ±2**52 will lose precision when converted to Double.)
    
    // the following properties are mainly for internal use, but SpecifierFormatter may also get them when rendering app roots
    public let target: AETarget
    
    private var _targetDescriptor: NSAppleEventDescriptor? = nil // targetDescriptor() creates an AEAddressDesc for the target process when dispatching first Apple event, caching it here for subsequent reuse
    
    private var _transactionID: AETransactionID = AE4.anyTransactionID
    
    public init(target: AETarget = .none) {
        self.target = target
    }
    
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
            case 98, 99, 67, 115, 83, 105: // (b, c, C, s, S, i) anything that will fit into SInt32 is packed as typeSInt32 for compatibility
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
            // Note: to maximize application compatibility, always preferentially encode integers as typeSInt32, as that's the traditional integer type recognized by all apps. (In theory, packing as typeSInt64 shouldn't be a problem as apps should coerce to whatever type they actually require before decoding, but not-so-well-designed Carbon apps sometimes explicitly typecheck instead, so will fail if the descriptor isn't the assumed typeSInt32.)
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
            
        // Cocoa collection classes don't support SelfPacking (though don't require it either since they're not generics); for now, just cast to Swift type on assumption that these are less common cases and Swift's ObjC bridge won't add significant cost, though they could be packed directly here if preferred
        case let obj as NSSet:
            return try (obj as Set).encodeAEDescriptor(self)
        case let obj as NSArray:
            return try (obj as Array).encodeAEDescriptor(self)
        case let obj as NSDictionary:
            return try (obj as Dictionary).encodeAEDescriptor(self)
            
        
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
            ()
        }
        throw PackError(object: value)
    }
    
}

// MARK: Descriptor decoding
extension App {
    
    public func decode<T>(_ desc: NSAppleEventDescriptor) throws -> T {
        if T.self == Any.self || T.self == AnyObject.self {
            return try self.decodeAsAny(desc) as! T
        } else if let t = T.self as? AEDecodable.Type {
            if let decoded = try t.init(from: desc, app: self) as? T {
                return decoded
            }
        } else if T.self == Query.self {
            if let result = try self.decodeAsAny(desc) as? T { // specifiers can be composed of several AE types, so decode first then check type
                return result
            } else {
                return RootSpecifier(.object(desc), app: self) as! T
            }
        } else if isMissingValue(desc) {
            throw DecodeError(app: self, descriptor: desc, type: T.self, message: "Can't coerce 'missing value' descriptor to \(T.self).") // Important: App must not decode a 'missing value' constant as anything except `MissingValue` or `nil` (i.e. the types to which it self-decodes). AppleScript doesn't have this problem as all descriptors decode to their own preferred type, but decode<T>() forces a descriptor to decode as a specific type or fail trying. While its role is to act as a `nil`-style placeholder when no other value is given, its descriptor type is typeType so left to its own devices it would naturally decode the same as any other typeType descriptor. e.g. One of AEM's vagaries is that it supports typeType to typeUnicodeText coercions, so while permitting cDocument to coerce to "docu" might be acceptable [if not exactly helpful], allowing cMissingValue to coerce to "msng" would defeat its whole purpose.
        }
        
        switch T.self {
        case is Bool.Type:
            return desc.booleanValue as! T
        case is Int.Type: // TO DO: this assumes Int will _always_ be 64-bit (on macOS); is that safe?
            if desc.descriptorType == AE4.Types.sInt32 { // shortcut for common case where descriptor is already a standard 32-bit int
                return Int(desc.int32Value) as! T
            } else if let result = self.decodeAsInt(desc) {
                return Int(result) as! T
            }
        case is UInt.Type:
            if let result = self.decodeAsInt(desc) {
                return Int(result) as! T
            }
        case is Double.Type:
            if let doubleDesc = desc.coerce(toDescriptorType: AE4.Types.ieee64BitFloatingPoint) {
                return Double(doubleDesc.doubleValue) as! T
            }
        case is String.Type, is NSString.Type:
            if let result = desc.stringValue {
                return result as! T
            }
        case is Symbol.Type:
            if symbolDescriptorTypes.contains(desc.descriptorType) {
                return Symbol(code: desc.typeCodeValue, type: desc.descriptorType) as! T
            }
        case is Date.Type, is NSDate.Type:
             if let result = desc.dateValue {
                 return result as! T
             }
        case is URL.Type, is NSURL.Type:
             if let result = desc.fileURLValue { // note: this coerces all file system-related descriptors down to typeFileURL before decoding them, so typeAlias/typeBookmarkData descriptors (which identify file system objects, not locations) won't round-trip and the resulting URL will only describe the file's location at the time the descriptor was decoded.
                 return result as! T
            }
        case is Int8.Type: // lack of common protocols on Integer types is a pain
            if let n = self.decodeAsInt(desc), let result = Int8(exactly: n) {
                return result as! T
            }
        case is Int16.Type:
            if let n = self.decodeAsInt(desc), let result = Int16(exactly: n) {
                return result as! T
            }
        case is Int32.Type:
            if let n = self.decodeAsInt(desc), let result = Int32(exactly: n) {
                return result as! T
            }
        case is Int64.Type:
            if let n = self.decodeAsInt(desc), let result = Int64(exactly: n) {
                return result as! T
            }
        case is UInt8.Type:
            if let n = self.decodeAsUInt(desc), let result = UInt8(exactly: n) {
                return result as! T
            }
        case is UInt16.Type:
            if let n = self.decodeAsUInt(desc), let result = UInt16(exactly: n) {
                return result as! T
            }
        case is UInt32.Type:
            if let n = self.decodeAsUInt(desc), let result = UInt32(exactly: n) {
                return result as! T
            }
        case is UInt64.Type:
            if let n = self.decodeAsUInt(desc), let result = UInt64(exactly: n) {
                return result as! T
            }
        case is Float.Type:
            if let doubleDesc = desc.coerce(toDescriptorType: AE4.Types.ieee64BitFloatingPoint),
                    let result = Float(exactly: doubleDesc.doubleValue) {
                return result as! T
            }
        case is AnyHashable.Type: // while records always decode as [Symbol:TYPE], [AnyHashable:TYPE] is a valid return type too
            if let result = try self.decodeAsAny(desc) as? AnyHashable {
                return result as! T
            }
        case is NSNumber.Type:
            switch desc.descriptorType {
            case AE4.Types.boolean, AE4.Types.true, AE4.Types.false:
                return NSNumber(value: desc.booleanValue) as! T
            case AE4.Types.sInt32, AE4.Types.sInt16:
                return NSNumber(value: desc.int32Value) as! T
            case AE4.Types.ieee64BitFloatingPoint, AE4.Types.ieee32BitFloatingPoint, AE4.Types._128BitFloatingPoint:
                return NSNumber(value: desc.doubleValue) as! T
            case AE4.Types.sInt64:
                return NSNumber(value: self.decodeAsInt(desc)!) as! T
            case AE4.Types.uInt32, AE4.Types.uInt16, AE4.Types.uInt64:
                return NSNumber(value: self.decodeAsUInt(desc)!) as! T
            default: // not a number, e.g. a string, so preferentially coerce and decode as Int64 or else Double, falling through on failure
                if let doubleDesc = desc.coerce(toDescriptorType: AE4.Types.ieee64BitFloatingPoint) {
                    let d = doubleDesc.doubleValue
                    if d.truncatingRemainder(dividingBy: 1) == 0, let i = self.decodeAsInt(desc) {
                        return NSNumber(value: i) as! T
                    } else {
                        return NSNumber(value: doubleDesc.doubleValue) as! T
                    }
                }
            }
        case is NSArray.Type:
            return try self.decode(desc) as Array<Any> as! T
        case is NSSet.Type:
            return try self.decode(desc) as Set<AnyHashable> as! T
        case is NSDictionary.Type:
            return try self.decode(desc) as Dictionary<Symbol,Any> as! T
        case is NSAppleEventDescriptor.Type:
            return desc as! T
        case let t:
            print(t)
        }
        // desc couldn't be coerced to the specified type
        let symbol = Symbol(code: desc.descriptorType, type: typeType)
        let typeName = String(fourCharCode: symbol.code)
        throw DecodeError(app: self, descriptor: desc, type: T.self, message: "Can't coerce \(typeName) descriptor to \(T.self).")
    }
    
    /******************************************************************************/
    // Convert an Apple event descriptor to its preferred Swift type, as determined by its descriptorType
    
    public func decodeAsAny(_ desc: NSAppleEventDescriptor) throws -> Any { // note: this never returns Optionals (i.e. cMissingValue AEDescs always decode as MissingValue when return type is Any) to avoid dropping user into Optional<T>.some(Optional<U>.none) hell.
        switch desc.descriptorType {
        case AE4.Types.null:
            return App.generic.application
        case AE4.Types.currentContainer:
            return App.generic.container
        case AE4.Types.objectBeingExamined:
            return App.generic.specimen
            // common AE types
        case AE4.Types.true, AE4.Types.false, AE4.Types.boolean:
            return desc.booleanValue
        case AE4.Types.sInt32, AE4.Types.sInt16:
            return desc.int32Value
        case AE4.Types.ieee64BitFloatingPoint, AE4.Types.ieee32BitFloatingPoint:
            return desc.doubleValue
        case AE4.Types._128BitFloatingPoint: // coerce down lossy
            guard let doubleDesc = desc.coerce(toDescriptorType: AE4.Types.ieee64BitFloatingPoint) else {
                throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Can't coerce 128-bit float to double.")
            }
            return doubleDesc.doubleValue
        case AE4.Types.text, AE4.Types.intlText, AE4.Types.utf8Text, AE4.Types.utf16ExternalRepresentation, AE4.Types.styledText, AE4.Types.unicodeText, AE4.Types.version:
            guard let result = desc.stringValue else { // this should never fail unless the AEDesc contains mis-encoded text data (e.g. claims to be typeUTF8Text but contains non-UTF8 byte sequences)
                throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Corrupt string descriptor.")
            }
            return result
        case AE4.Classes.char:
            let data = desc.data
            return try data.withUnsafeBytes { bytes in
                switch data.count {
                case 1:
                    return Character(Unicode.Scalar(bytes.first!))
                case 2:
                    let char16s = bytes.bindMemory(to: UInt16.self)
                    guard let scalar = char16s.first.flatMap({ Unicode.Scalar($0) }) else {
                        throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Corrupt UTF-16 character descriptor.")
                    }
                    return Character(scalar)
                case 4:
                    let char32s = bytes.bindMemory(to: UInt32.self)
                    guard let scalar = char32s.first.flatMap({ Unicode.Scalar($0) }) else {
                        throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Corrupt UTF-32 character descriptor.")
                    }
                    return Character(scalar)
                default:
                    throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Character descriptor has irregular byte count.")
                }
            }
        case AE4.Types.longDateTime:
            guard let result = desc.dateValue else { // this should never fail unless the AEDesc contains bad data
                throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Corrupt descriptor.")
            }
            return result
        case AE4.Types.list:
            return try Array(from: desc, app: self) as [Any]
        case AE4.Types.record:
            return try Dictionary(from: desc, app: self) as [Symbol:Any]
        case AE4.Types.alias, AE4.Types.bookmarkData, AE4.Types.fileURL, AE4.Types.fsRef, AE4.Types.fss: // note: typeFSS is long defunct so shouldn't be encountered unless dealing with exceptionally old 32-bit Carbon apps, while a `file "HFS:PATH:"` object specifier (typeObjectSpecifier of cFile; basically an AppleScript kludge-around to continue supporting the `file [specifier] "HFS:PATH:"` syntax form despite typeFSS going away) is indistinguishable from any other object specifier so will decode as an explicit `APPLICATION().files["HFS:PATH:"]` or `APPLICATION().elements("file")["HFS:PATH:"]` specifier depending on whether or not the glue defines a `file[s]` keyword (TBH, not sure if there are any apps do return AEDescs that represent file system locations this way.)
            guard let result = desc.fileURLValue else { // ditto
                throw DecodeError(app: self, descriptor: desc, type: Any.self, message: "Corrupt descriptor.")
            }
            return result
        case AE4.Types.type, AE4.Types.enumerated, AE4.Types.property, AE4.Types.keyword:
            return isMissingValue(desc) ? MissingValue : Symbol(code: desc.typeCodeValue, type: desc.descriptorType)
            // object specifiers
        case AE4.Types.objectSpecifier:
            return try self.decodeAsObjectSpecifier(desc)
        case AE4.Types.insertionLoc:
            return try self.decodeAsInsertionLoc(desc)
        case AE4.Types.null: // null descriptor indicates object specifier root
            return self.application
        case AE4.Types.currentContainer:
            return self.container
        case AE4.Types.objectBeingExamined:
            return self.specimen
        case AE4.Types.compDescriptor:
            return try self.decodeAsComparisonDescriptor(desc)
        case AE4.Types.logicalDescriptor:
            return try self.decodeAsLogicalDescriptor(desc)
            
            // less common types
        case AE4.Types.sInt64:
            return self.decodeAsInt(desc)!
        case AE4.Types.uInt64, AE4.Types.uInt32, AE4.Types.uInt16:
            return self.decodeAsUInt(desc)!
        case AE4.Types.qdPoint, AE4.Types.qdRectangle, AE4.Types.rgbColor:
            return try self.decode(desc) as [Int]
            // note: while there are also several AEAddressDesc types used to identify applications, these are very rarely used as command results (e.g. the `choose application` OSAX) and there's little point decoding them anway as the only type they can automatically be mapped to is AEApplication, which has only minimal functionality anyway. Also unsupported are unit types as they only cover a handful of measurement types and in practice aren't really used for anything except measurement conversions in AppleScript.
        default:
            if desc.isRecordDescriptor {
                return try Dictionary(from: desc, app: self) as [Symbol:Any]
            }
            return desc
        }
    }
    
}

private let _absoluteOrdinalCodes: Set<OSType> = Set(AE4.AbsoluteOrdinal.allCases.map { $0.rawValue })
private let _relativeOrdinalCodes: Set<OSType> = Set(AE4.RelativeOrdinal.allCases.map { $0.rawValue })

private let _comparisonOperatorCodes: Set<OSType> = Set(AE4.Comparison.allCases.map { $0.rawValue } + AE4.Containment.allCases.map { $0.rawValue } + [AE4.notEquals, AE4.isIn])
private let _logicalOperatorCodes: Set<OSType> = Set(AE4.LogicalOperator.allCases.map { $0.rawValue })

// MARK: Decoding helpers
extension App {

    private func decodeAsInt(_ desc: NSAppleEventDescriptor) -> Int? {
        // coerce the descriptor (whatever it is - typeSInt16, typeUInt32, typeUnicodeText, etc.) to typeSIn64 (hoping the Apple Event Manager has remembered to install TYPE-to-SInt64 coercion handlers for all these types too), and decode as Int[64]
        if let intDesc = desc.coerce(toDescriptorType: AE4.Types.sInt64) {
            var result: Int64 = 0
            (intDesc.data as NSData).getBytes(&result, length: MemoryLayout<Int64>.size)
            return Int(result) // caution: this assumes Int will always be 64-bit
        } else {
            return nil
        }
    }

    private func decodeAsUInt(_ desc: NSAppleEventDescriptor) -> UInt? {
            // as above, but for unsigned ints
        if let intDesc = desc.coerce(toDescriptorType: AE4.Types.uInt64) {
            var result: UInt64 = 0
            (intDesc.data as NSData).getBytes(&result, length: MemoryLayout<UInt64>.size)
            return UInt(result) // caution: this assumes UInt will always be 64-bit
        } else {
            return nil
        }
    }
    
    func decodeAsInsertionLoc(_ desc: NSAppleEventDescriptor) throws -> Specifier {
        guard
            let _ = desc.forKeyword(AE4.InsertionSpecifierKeywords.object), // only used to check InsertionLoc record is correctly formed
            let insertionLocation = desc.forKeyword(AE4.InsertionSpecifierKeywords.position)
        else {
                throw DecodeError(app: self, descriptor: desc, type: InsertionSpecifier.self, message: "Can't decode malformed insertion specifier.")
        }
        return InsertionSpecifier(insertionLocation: insertionLocation, parentQuery: try decode(desc), app: self)
    }
    
    func decodeAsObjectSpecifier(_ desc: NSAppleEventDescriptor) throws -> Specifier {
        guard
            let parentDesc = desc.forKeyword(AE4.ObjectSpecifierKeywords.container),
            let wantType = desc.forKeyword(AE4.ObjectSpecifierKeywords.desiredClass),
            let selectorForm = desc.forKeyword(AE4.ObjectSpecifierKeywords.keyForm),
            let selectorDesc = desc.forKeyword(AE4.ObjectSpecifierKeywords.keyData)
        else {
            throw DecodeError(app: self, descriptor: desc, type: ObjectSpecifier.self, message: "Can't decode malformed object specifier.")
        }
        do { // decode selectorData, unless it's a property code or absolute/relative ordinal (in which case use its 'prop'/'enum' descriptor as-is)
            var selectorData: Any = selectorDesc // the selector won't be decoded if it's a property/relative/absolute ordinal
            var objectSpecifierClass = ObjectSpecifier.self // most reference forms describe one-to-one relationships
            switch AE4.IndexForm(rawValue: selectorForm.enumCodeValue) {
            case .propertyID: // property
                if ![AE4.Types.type, AE4.Types.property].contains(selectorDesc.descriptorType) {
                    throw DecodeError(app: self, descriptor: desc, type: ObjectSpecifier.self, message: "Can't decode malformed object specifier.")
                }
            case .relativePosition: // before/after
                if !(selectorDesc.descriptorType == AE4.Types.enumerated && _relativeOrdinalCodes.contains(selectorDesc.enumCodeValue)) {
                    throw DecodeError(app: self, descriptor: desc, type: ObjectSpecifier.self,
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
                    throw DecodeError(app: self, descriptor: selectorDesc, type: RangeSelector.self, message: "Malformed selector in by-range specifier.")
                }
                guard
                    let startDesc = selectorDesc.forKeyword(AE4.RangeSpecifierKeywords.start),
                    let stopDesc = selectorDesc.forKeyword(AE4.RangeSpecifierKeywords.stop)
                else {
                    throw DecodeError(app: self, descriptor: selectorDesc, type: RangeSelector.self, message: "Malformed selector in by-range specifier.")
                }
                do {
                    selectorData = RangeSelector(start: try decodeAsAny(startDesc), stop: try self.decodeAsAny(stopDesc), wantType: wantType)
                } catch {
                    throw DecodeError(app: self, descriptor: selectorDesc, type: RangeSelector.self, message: "Couldn't decode start/stop selector in by-range specifier.")
                }
            case .test: // by-range = one-to-many relationship
                objectSpecifierClass = MultipleObjectSpecifier.self
                selectorData = try decode(selectorDesc)
                if !(selectorData is Query) {
                    throw DecodeError(app: self, descriptor: selectorDesc, type: Query.self, message: "Malformed selector in by-test specifier.")
                }
            default: // by-name or by-ID
                selectorData = try decode(selectorDesc)
            }
            return objectSpecifierClass.init(wantType: wantType,
                                             selectorForm: selectorForm, selectorData: selectorData,
                                             parentQuery: try decode(parentDesc) as Query,
                                             app: self)
        } catch {
            throw DecodeError(app: self, descriptor: desc, type: ObjectSpecifier.self, message: "Can't decode object specifier's selector data.", cause: error)
        }
    }
    
    func decodeAsComparisonDescriptor(_ desc: NSAppleEventDescriptor) throws -> TestClause {
        if
            let operatorType = desc.forKeyword(AE4.TestPredicateKeywords.comparisonOperator),
            let operand1Desc = desc.forKeyword(AE4.TestPredicateKeywords.firstObject),
            let operand2Desc = desc.forKeyword(AE4.TestPredicateKeywords.secondObject),
            !_comparisonOperatorCodes.contains(operatorType.enumCodeValue)
        {
                // don't bother with dedicated error reporting here as malformed operand descs that cause the following decode calls to fail are unlikely in practice, and will still be caught and reported further up the call chain anyway
                let operand1 = try decodeAsAny(operand1Desc)
                let operand2 = try decodeAsAny(operand2Desc)
                if operatorType.typeCodeValue == AE4.Containment.contains.rawValue && !(operand1 is ObjectSpecifier) {
                    if let op2 = operand2 as? ObjectSpecifier {
                        return ComparisonTest(operatorType: AE4.Descriptors.ContainmentTests.isIn, operand1: op2, operand2: operand1, app: self)
                    } // else fall through to throw
                } else if let op1 = operand1 as? ObjectSpecifier {
                    return ComparisonTest(operatorType: operatorType, operand1: op1, operand2: operand2, app: self)
                } // else fall through to throw
        }
        throw DecodeError(app: self, descriptor: desc, type: TestClause.self, message: "Can't decode comparison test: malformed descriptor.")
    }
    
    func decodeAsLogicalDescriptor(_ desc: NSAppleEventDescriptor) throws -> TestClause {
        if
            let operatorType = desc.forKeyword(AE4.TestPredicateKeywords.logicalOperator),
            let operandsDesc = desc.forKeyword(AE4.TestPredicateKeywords.object),
            !_logicalOperatorCodes.contains(operatorType.enumCodeValue)
        {
                let operands = try decode(operandsDesc) as [TestClause]
                return LogicalTest(operatorType: operatorType, operands: operands, app: self)
        }
        throw DecodeError(app: self, descriptor: desc, type: TestClause.self, message: "Can't decode logical test: malformed descriptor.")
    }
    
}

// MARK: Target encoding
extension App {
    
    public func targetDescriptor() throws -> NSAppleEventDescriptor? {
        if _targetDescriptor == nil {
            _targetDescriptor = try target.descriptor(launchOptions)
        }
        return _targetDescriptor
    }
    
}

private let defaultSendMode = SendOptions.defaultOptions.union(SendOptions.canSwitchLayer)
private let defaultIgnorances = packConsideringAndIgnoringFlags([.case])

// if target process is no longer running, Apple Event Manager will return an error when an event is sent to it
private let RelaunchableErrorCodes: Set<Int> = [-600, -609]
// if relaunchMode = .limited, only 'launch' and 'run' are allowed to restart a local application that's been quit
private let LimitedRelaunchEvents: [(OSType,OSType)] = [(AE4.Events.Core.eventClass, AE4.Events.Core.IDs.openApplication), (AE4.Events.AppleScript.eventClass, AE4.Events.AppleScript.IDs.launch)]

// MARK: Apple event sending
extension App {
    
    private func send(event: NSAppleEventDescriptor, sendMode: SendOptions, timeout: TimeInterval) throws -> NSAppleEventDescriptor {
        do {
            return try event.sendEvent(options: sendMode, timeout: timeout) // throws NSError on AEM errors (but not app errors)
        } catch {
            // 'launch' events normally return 'not handled' errors, so just ignore those
            // TO DO: this is wrong; -1708 will be in reply event, not in AEM error; FIX
            if
                (error as NSError).code == -1708,
                event.attributeDescriptor(forKeyword: AE4.Attributes.eventClass)!.typeCodeValue == AE4.Events.AppleScript.eventClass,
                event.attributeDescriptor(forKeyword: AE4.Attributes.eventID)!.typeCodeValue == AE4.Events.AppleScript.IDs.launch
            {
                // not a full AppleEvent desc, but reply event's attributes aren't used so is equivalent to a reply event containing neither error nor result
                    return NSAppleEventDescriptor.record()
            } else {
                throw error
            }
        }
    }
    
    public func sendAppleEvent<Result>(name: String?, eventClass: OSType, eventID: OSType,
                                  parentSpecifier: Specifier, // the Specifier on which the command method was called; see special-case packing logic below
                                  directParameter: Any = NoParameter, // the first (unnamed) parameter to the command method; see special-case packing logic below
                                  keywordParameters: [KeywordParameter] = [], // the remaining named parameters
                                  requestedType: Symbol? = nil, // event's `as` parameter, if any (note: while a `keyAERequestedType` parameter can be supplied via `keywordParameters:`, it will be ignored if `requestedType:` is given)
                                  waitReply: Bool = true, // wait for application to respond before returning?
                                  sendOptions: SendOptions? = nil, // raw send options (these are rarely needed); if given, `waitReply:` is ignored
                                  withTimeout: TimeInterval? = nil, // no. of seconds to wait before raising timeout error (-1712); may also be default/never
                                  ignoring ignorances: Considerations? = nil
    ) throws -> Result // coerce and decode result as this type or return raw reply event if T is NSDescriptor; default is Any
    {
        // note: human-readable command and parameter names are only used (if known) in error messages
        // note: all errors occurring within this method are caught and rethrown as CommandError, allowing error message to provide a description of the failed command as well as the error itself
        var sentEvent: NSAppleEventDescriptor?, repliedEvent: NSAppleEventDescriptor?
        do {
            // Create a new AppleEvent descriptor (throws ConnectionError if target app isn't found)
            let event = NSAppleEventDescriptor(eventClass: eventClass, eventID: eventID, targetDescriptor: try self.targetDescriptor(),
                                               returnID: AE4.autoGenerateReturnID, transactionID: AE4.anyTransactionID)
            // encode its keyword parameters
            for (paramName, code, value) in keywordParameters where parameterExists(value) {
                do {
                    event.setDescriptor(try self.encode(value), forKeyword: code)
                } catch {
                    throw AutomationError(code: error._code, message: "Invalid '\(paramName ?? String(fourCharCode: code))' parameter.", cause: error)
                }
            }
            // encode event's direct parameter and/or subject attribute
            let hasDirectParameter = parameterExists(directParameter)
            if hasDirectParameter { // if the command includes a direct parameter, encode that normally as its direct param
                event.setParam(try self.encode(directParameter), forKeyword: AE4.Keywords.directObject)
            }
            // if command method was called on root Application (null) object, the event's subject is also null...
            var subjectDesc = applicationRoot
            // ... but if the command was called on a Specifier, decide if that specifier should be packed as event's subject
            // or, as a special case, used as event's keyDirectObject/keyAEInsertHere parameter for user's convenience
            if !(parentSpecifier is RootSpecifier) { // technically Application, but there isn't an explicit class for that
                if eventClass == AE4.Suites.coreSuite && eventID == AE4.AESymbols.createElement { // for user's convenience, `make` command is treated as a special case
                    // if `make` command is called on a specifier, use that specifier as event's `at` parameter if not already given
                    if event.paramDescriptor(forKeyword: AE4.Keywords.insertHere) != nil { // an `at` parameter was already given, so encode parent specifier as event's subject attribute
                        subjectDesc = try self.encode(parentSpecifier)
                    } else { // else encode parent specifier as event's `at` parameter and use null as event's subject attribute
                        event.setParam(try self.encode(parentSpecifier), forKeyword: AE4.Keywords.insertHere)
                    }
                } else { // for all other commands, check if a direct parameter was already given
                    if hasDirectParameter { // encode the parent specifier as the event's subject attribute
                        subjectDesc = try self.encode(parentSpecifier)
                    } else { // else encode parent specifier as event's direct parameter and use null as event's subject attribute
                        event.setParam(try self.encode(parentSpecifier), forKeyword: AE4.Keywords.directObject)
                    }
                }
            }
            event.setAttribute(subjectDesc, forKeyword: AE4.Attributes.subject)
            // encode requested type (`as`) parameter, if specified; note: most apps ignore this, but a few may recognize it (usually in `get` commands)  even if they don't define it in their dictionary (another AppleScript-introduced quirk); e.g. `Finder().home.get(requestedType:FIN.alias) as URL` tells Finder to return a typeAlias descriptor instead of typeObjectSpecifier, which can then be decoded as URL
            if let type = requestedType {
                event.setDescriptor(NSAppleEventDescriptor(typeCode: type.code), forKeyword: AE4.Keywords.requestedType)
            }
            // event attributes
            // (note: most apps ignore considering/ignoring attributes, and always ignore case and consider everything else)
            let (ignorances, consideringIgnoring) = ignorances == nil ? defaultIgnorances : packConsideringAndIgnoringFlags(ignorances!)
            event.setAttribute(ignorances, forKeyword: AE4.Attributes.considerations)
            event.setAttribute(consideringIgnoring, forKeyword: AE4.Attributes.considsAndIgnores)
            // send the event
            let sendMode: SendOptions = [.alwaysInteract, .waitForReply] //sendOptions ?? defaultSendMode.union(waitReply ? .waitForReply : .noReply)
            let timeout = withTimeout ?? defaultTimeout
            var replyEvent: NSAppleEventDescriptor
            sentEvent = event
            do {
                replyEvent = try self.send(event: event, sendMode: sendMode, timeout: timeout) // throws NSError on AEM error
            } catch { // handle errors raised by Apple Event Manager (e.g. timeout, process not found)
                if RelaunchableErrorCodes.contains((error as NSError).code) && self.target.isRelaunchable && (relaunchMode == .always
                        || (relaunchMode == .limited && LimitedRelaunchEvents.contains(where: {$0.0 == eventClass && $0.1 == eventID}))) {
                    // event failed as target process has quit since previous event; recreate AppleEvent with new address and resend
                    self._targetDescriptor = nil
                    let event2 = NSAppleEventDescriptor(eventClass: eventClass, eventID: eventID, targetDescriptor: try self.targetDescriptor(),
                                                        returnID: AE4.autoGenerateReturnID, transactionID: AE4.anyTransactionID)
                    let count = event.numberOfItems
                    if count > 0 {
                        for i in 1...count {
                            event2.setParam(event.atIndex(i)!, forKeyword: event.keywordForDescriptor(at: i))
                        }
                    }
                    for key in [AE4.Attributes.subject, AE4.Attributes.considerations, AE4.Attributes.considsAndIgnores] {
                        event2.setAttribute(event.attributeDescriptor(forKeyword: key)!, forKeyword: key)
                    }
                    replyEvent = try self.send(event: event2, sendMode: sendMode, timeout: timeout)
                } else {
                    throw error
                }
            }
            repliedEvent = replyEvent
            if sendMode.contains(.waitForReply) {
                if Result.self == ReplyEventDescriptor.self { // return the entire reply event as-is
                    return ReplyEventDescriptor(descriptor: replyEvent) as! Result
                } else if replyEvent.paramDescriptor(forKeyword: AE4.Keywords.errorNumber)?.int32Value ?? 0 != 0 { // check if an application error occurred
                    throw AutomationError(code: Int(replyEvent.paramDescriptor(forKeyword: AE4.Keywords.errorNumber)!.int32Value))
                } else if let resultDesc = replyEvent.paramDescriptor(forKeyword: AE4.Keywords.directObject) {
                    return try self.decode(resultDesc) as Result
                } // no return value or error, so fall through
            } else if sendMode.contains(.queueReply) { // get the return ID that will be used by the reply event so that client code's main loop can identify that reply event in its own event queue later on
                guard let returnIDDesc = event.attributeDescriptor(forKeyword: AE4.Attributes.returnID) else { // sanity check
                    throw AutomationError(code: defaultErrorCode, message: "Can't get keyReturnIDAttr.")
                }
                return try self.decode(returnIDDesc)
            }
            // note that some Apple event handlers intentionally return a void result (e.g. `set`, `quit`), and now and again a crusty old Carbon app will forget to supply a return value where one is expected; however, rather than add `COMMAND()->void` methods to glue files (which would only cover the first case), it's simplest just to return an 'empty' value which covers both use cases
            if let result = MissingValue as? Result { // this will succeed when T is Any (which it always will be when the caller ignores the command's result)
                return result
            }
            throw AutomationError(code: defaultErrorCode, message: "Caller requested \(Result.self) result but application didn't return anything.")
        } catch {
            let commandDescription = CommandDescription(name: name, eventClass: eventClass, eventID: eventID, parentSpecifier: parentSpecifier,
                                                        directParameter: directParameter, keywordParameters: keywordParameters,
                                                        requestedType: requestedType, waitReply: waitReply,
                                                        withTimeout: withTimeout, considering: ignorances)
            throw CommandError(commandInfo: commandDescription, app: self, event: sentEvent, reply: repliedEvent, cause: error)
        }
    }
    
    
    // convenience shortcut for dispatching events using raw OSType codes only (the above method also requires human-readable command and parameter names to be supplied for error reporting purposes); users should call this via one of the `sendAppleEvent` methods on `AEApplication`/`AEItem`
    
    public func sendAppleEvent<T>(eventClass: OSType, eventID: OSType, parentSpecifier: Specifier, parameters: [OSType:Any] = [:],
                                  requestedType: Symbol? = nil, waitReply: Bool = true, sendOptions: SendOptions? = nil,
                                  withTimeout: TimeInterval? = nil, ignoring: Considerations? = nil) throws -> T {
        var parameters = parameters
        let directParameter = parameters.removeValue(forKey: AE4.Keywords.directObject) ?? NoParameter
        let keywordParameters: [KeywordParameter] = parameters.map({(name: nil, code: $0, value: $1)})
        return try self.sendAppleEvent(name: nil, eventClass: eventClass, eventID: eventID, parentSpecifier: parentSpecifier, directParameter: directParameter, keywordParameters: keywordParameters, requestedType: requestedType, waitReply: waitReply, sendOptions: sendOptions, withTimeout: withTimeout, ignoring: ignoring)
    }
    
}

// MARK: Transactions
// In practice, there are few, if any, currently available apps that support transactions, but it's included for completeness.
extension App {
    
    public func doTransaction<T>(session: Any? = nil, closure: () throws -> (T)) throws -> T {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
        }
        assert(self._transactionID == AE4.anyTransactionID, "Transaction \(self._transactionID) already active.")
        self._transactionID = try self.sendAppleEvent(name: nil, eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.begin, parentSpecifier: App.generic.application, directParameter: session as Any) as AETransactionID
        defer {
            self._transactionID = AE4.anyTransactionID
        }
        var result: T
        do {
            result = try closure()
        } catch { // abort transaction, then rethrow closure error
            let _ = try? self.sendAppleEvent(name: nil, eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.terminated,
                                             parentSpecifier: App.generic.application) as Any
            throw error
        } // else end transaction
        _ = try self.sendAppleEvent(name: nil, eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.end, parentSpecifier: App.generic.application) as Any
        return result
    }
    
}

/******************************************************************************/

/// Used by App.sendAppleEvent() to encode Considerations as enumConsiderations (old-style) and enumConsidsAndIgnores (new-style) attributes
let considerationsTable: [(Consideration, NSAppleEventDescriptor, UInt32, UInt32)] = [
    // note: Swift mistranslates considering/ignoring mask constants as Int, not UInt32, so redefine them here
    (.case,             NSAppleEventDescriptor(enumCode: AE4.Considerations.case),              0x00000001, 0x00010000),
    (.diacritic,        NSAppleEventDescriptor(enumCode: AE4.Considerations.diacritic),         0x00000002, 0x00020000),
    (.whiteSpace,       NSAppleEventDescriptor(enumCode: AE4.Considerations.whiteSpace),        0x00000004, 0x00040000),
    (.hyphens,          NSAppleEventDescriptor(enumCode: AE4.Considerations.hyphens),           0x00000008, 0x00080000),
    (.expansion,        NSAppleEventDescriptor(enumCode: AE4.Considerations.expansion),         0x00000010, 0x00100000),
    (.punctuation,      NSAppleEventDescriptor(enumCode: AE4.Considerations.punctuation),       0x00000020, 0x00200000),
    (.numericStrings,   NSAppleEventDescriptor(enumCode: AE4.Considerations.numericStrings),    0x00000080, 0x00800000),
]

private func packConsideringAndIgnoringFlags(_ ignorances: Considerations) -> (NSAppleEventDescriptor, NSAppleEventDescriptor) {
    let ignorancesListDesc = NSAppleEventDescriptor.list()
    var consideringIgnoringFlags: UInt32 = 0
    for (consideration, considerationDesc, consideringMask, ignoringMask) in considerationsTable {
        if ignorances.contains(consideration) {
            consideringIgnoringFlags |= ignoringMask
            ignorancesListDesc.insert(considerationDesc, at: 0)
        } else {
            consideringIgnoringFlags |= consideringMask
        }
    }
    // old-style flags (list of enums), new-style flags (bitmask)
    return (ignorancesListDesc, NSAppleEventDescriptor(uint32: consideringIgnoringFlags))
}
