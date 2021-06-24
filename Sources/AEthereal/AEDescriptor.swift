// See README.md for licensing information.

import Foundation

public typealias AEDescriptor = NSAppleEventDescriptor

extension AEDescriptor {
    
    public var type: AE4.AEType {
        AE4.AEType(rawValue: descriptorType)
    }
    
    public static var missingValue: AEDescriptor {
        AEDescriptor(typeCode: AE4.Classes.missingValue)
    }
    public var isMissingValue: Bool {
        type == .type && typeCodeValue == AE4.Classes.missingValue
    }
    
    public convenience init?(type: AE4.AEType, bytes: UnsafeRawPointer?, length byteCount: Int) {
        self.init(descriptorType: type.rawValue, bytes: bytes, length: byteCount)
    }

    public convenience init?(type: AE4.AEType, data: Data?) {
        self.init(descriptorType: type.rawValue, data: data)
    }
    
    public convenience init(type: AE4, code: AE4) {
        var code = code
        self.init(descriptorType: type, bytes: &code, length: MemoryLayout<AE4>.size)!
    }
    public convenience init(type: AE4.AEType, code: AE4) {
        self.init(type: type.rawValue, code: code)
    }
    
    public convenience init(typeCode: AE4.AEType) {
        self.init(typeCode: typeCode.rawValue)
    }
    
    public convenience init(uint32: UInt32) {
        var uint32 = uint32
        self.init(type: AE4.AEType.uInt32, bytes: &uint32, length: MemoryLayout<UInt32>.size)!
    }
    public convenience init(int64: Int64) {
        var int64 = int64
        self.init(type: AE4.AEType.sInt64, bytes: &int64, length: MemoryLayout<Int64>.size)!
    }
    public convenience init(uint64: UInt64) {
        var uint64 = uint64
        self.init(type: AE4.AEType.uInt64, bytes: &uint64, length: MemoryLayout<UInt64>.size)!
    }
    
    public var int64Value: Int64? {
        if let int64 = coerce(to: .sInt64) {
            var value: Int64 = 0
            withUnsafeMutableBytes(of: &value) { value in
                _ = int64.data.copyBytes(to: value, count: MemoryLayout<Int64>.size)
            }
            return value
        }
        return nil
    }
    public var uint64Value: UInt64? {
        if let uint64 = coerce(to: .uInt64) {
            var value: UInt64 = 0
            withUnsafeMutableBytes(of: &value) { value in
                _ = uint64.data.copyBytes(to: value, count: MemoryLayout<UInt64>.size)
            }
            return value
        }
        return nil
    }

    public convenience init(eventClass: AEEventClass, eventID: AEEventID, target: AEDescriptor?, returnID: AEReturnID = .auto, transactionID: AETransactionID = .any) {
        self.init(eventClass: eventClass, eventID: eventID, targetDescriptor: target, returnID: returnID, transactionID: transactionID)
    }
    
    public static func record(type: AE4.AEType = .record, _ kv: KeyValuePairs<AE4, AEDescriptor> = [:]) -> AEDescriptor? {
        guard let record = self.record().coerce(to: type) else {
            return nil
        }
        record.add(kv)
        return record
    }
    
    public static func objectSpecifier(container: AEEncodable, type: AE4.AEType, form: AE4.IndexForm, data: AEEncodable, app: App) throws -> AEDescriptor {
        AEDescriptor.record(type: .objectSpecifier, [
            AE4.ObjectSpecifierKeywords.container: try container.encodeAEDescriptor(app),
            AE4.ObjectSpecifierKeywords.desiredClass: try type.encodeAEDescriptor(app),
            AE4.ObjectSpecifierKeywords.keyForm: form.encodeAEDescriptor(app),
            AE4.ObjectSpecifierKeywords.keyData: try data.encodeAEDescriptor(app)
        ])!
    }
    public static func insertionSpecifier(container: AEEncodable, location: AEEncodable, app: App) throws -> AEDescriptor {
        AEDescriptor.record(type: .insertionLoc, [
            AE4.InsertionSpecifierKeywords.object: try container.encodeAEDescriptor(app),
            AE4.InsertionSpecifierKeywords.position: try location.encodeAEDescriptor(app)
        ])!
    }
    public static func range(start: AEEncodable, stop: AEEncodable, app: App) throws -> AEDescriptor {
        AEDescriptor.record(type: .rangeDescriptor, [
            AE4.RangeSpecifierKeywords.start: try start.encodeAEDescriptor(app),
            AE4.RangeSpecifierKeywords.stop: try start.encodeAEDescriptor(app)
        ])!
    }
    public static func comparison(operator: AE4.Comparison, lhs: AEEncodable, rhs: AEEncodable, app: App) throws -> AEDescriptor {
        AEDescriptor.record(type: .compDescriptor, [
            AE4.TestPredicateKeywords.comparisonOperator: `operator`.encodeAEDescriptor(app),
            AE4.TestPredicateKeywords.firstObject: try lhs.encodeAEDescriptor(app),
            AE4.TestPredicateKeywords.secondObject: try rhs.encodeAEDescriptor(app)
        ])!
    }
    public static func logical(operator: AE4.LogicalOperator, operands: [AEEncodable], app: App) throws -> AEDescriptor {
        AEDescriptor.record(type: .logicalDescriptor, [
            AE4.TestPredicateKeywords.logicalOperator: `operator`.encodeAEDescriptor(app),
            AE4.TestPredicateKeywords.logicalTerms: try operands.encodeAEDescriptor(app)
        ])!
    }
    
    public static var appRoot: AEDescriptor {
        .null()
    }
    public static var containerRoot: AEDescriptor {
        AEDescriptor(type: .currentContainer, data: nil)!
    }
    public static var specimenRoot: AEDescriptor {
        AEDescriptor(type: .objectBeingExamined, data: nil)!
    }
    
    public func coerce(to type: AE4.AEType) -> AEDescriptor? {
        coerce(toDescriptorType: type.rawValue)
    }
    
    public subscript(_ keyword: AE4) -> AEDescriptor? {
        get {
            paramDescriptor(forKeyword: keyword)
        }
        set {
            if let newValue = newValue {
                setDescriptor(newValue, forKeyword: keyword)
            } else {
                removeParamDescriptor(withKeyword: keyword)
            }
        }
    }
    
    public func add(_ kv: KeyValuePairs<AE4, AEDescriptor>) {
        for (key, value) in kv {
            self[key] = value
        }
    }
    
}

// MARK: AEEncodable
extension AEDescriptor: AEEncodable {
    
    public func encodeAEDescriptor(_ app: App) -> AEDescriptor {
        self
    }
    
}
