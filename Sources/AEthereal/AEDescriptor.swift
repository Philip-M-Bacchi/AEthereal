// See README.md for licensing information.

import Foundation

public final class AEDescriptor: NSAppleEventDescriptor {
    
    public var type: AE4.AEType {
        AE4.AEType(rawValue: descriptorType)
    }
    
    public static var missingValue: AEDescriptor {
        AEDescriptor(typeCode: .missingValue)
    }
    public var isMissingValue: Bool {
        type == .type && typeCodeValue == AE4.AEType.missingValue.rawValue
    }
    
    public override init(aeDescNoCopy aeDesc: UnsafePointer<AEDesc>) {
        super.init(aeDescNoCopy: aeDesc)
    }
    public convenience init(_ descriptor: NSAppleEventDescriptor) {
        self.init(aeDescNoCopy: (descriptor.copy() as! NSAppleEventDescriptor).aeDesc!)
    }
    
    public override class func null() -> AEDescriptor {
        AEDescriptor(super.null())
    }
    public static override func list() -> AEDescriptor {
        AEDescriptor(super.list())
    }
    public static override func record() -> AEDescriptor {
        AEDescriptor(super.record())
    }
    
    public convenience init(type: AE4.AEType, bytes: UnsafeRawPointer?, length byteCount: Int) {
        self.init(NSAppleEventDescriptor(descriptorType: type.rawValue, bytes: bytes, length: byteCount)!)
    }

    public convenience init(type: AE4.AEType, data: Data?) {
        self.init(NSAppleEventDescriptor(descriptorType: type.rawValue, data: data)!)
    }
    
    public convenience init(type: AE4.AEType, code: AE4) {
        var code = code
        self.init(type: type, bytes: &code, length: MemoryLayout<AE4>.size)
    }
    
    public convenience init(typeCode: AE4.AEType) {
        self.init(NSAppleEventDescriptor(typeCode: typeCode.rawValue))
    }
    
    public convenience init(int32: Int32) {
        self.init(NSAppleEventDescriptor(int32: int32))
    }
    public convenience init(uint32: UInt32) {
        var uint32 = uint32
        self.init(type: AE4.AEType.uInt32, bytes: &uint32, length: MemoryLayout<UInt32>.size)
    }
    public convenience init(int64: Int64) {
        var int64 = int64
        self.init(type: AE4.AEType.sInt64, bytes: &int64, length: MemoryLayout<Int64>.size)
    }
    public convenience init(uint64: UInt64) {
        var uint64 = uint64
        self.init(type: AE4.AEType.uInt64, bytes: &uint64, length: MemoryLayout<UInt64>.size)
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
    
    public convenience init(boolean: Bool) {
        self.init(NSAppleEventDescriptor(boolean: boolean))
    }
    public convenience init(double: Double) {
        self.init(NSAppleEventDescriptor(double: double))
    }
    public convenience init(string: String) {
        self.init(NSAppleEventDescriptor(string: string))
    }
    public convenience init(date: Date) {
        self.init(NSAppleEventDescriptor(date: date))
    }
    public convenience init(fileURL: URL) {
        self.init(NSAppleEventDescriptor(fileURL: fileURL))
    }
    
    public convenience init(point: CGPoint) {
        var data = Data(capacity: 2)
        data.append(point.y)
        data.append(point.x)
        self.init(type: .qdPoint, data: data)
    }
    public var pointValue: CGPoint? {
        guard let point = coerce(to: .qdPoint) else {
            return nil
        }
        
        let data = point.data
        let scalarSize = MemoryLayout<Int16>.size
        
        var y: Int16 = 0
        withUnsafeMutableBytes(of: &y) { y in
            _ = data.copyBytes(to: y, from: 0..<scalarSize)
        }
        var x: Int16 = 0
        withUnsafeMutableBytes(of: &x) { x in
            _ = data.copyBytes(to: x, from: scalarSize..<(2 * scalarSize))
        }
        
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    public convenience init(rect: CGRect) {
        var data = Data(capacity: 4)
        data.append(rect.minY)
        data.append(rect.minX)
        data.append(rect.maxY)
        data.append(rect.maxX)
        self.init(type: .qdRectangle, data: data)
    }
    public var rectValue: CGRect? {
        guard let rect = coerce(to: .qdRectangle) else {
            return nil
        }
        
        let data = rect.data
        let scalarSize = MemoryLayout<Int16>.size
        
        var y0: Int16 = 0
        withUnsafeMutableBytes(of: &y0) { y0 in
            _ = data.copyBytes(to: y0, from: 0..<scalarSize)
        }
        var x0: Int16 = 0
        withUnsafeMutableBytes(of: &x0) { x0 in
            _ = data.copyBytes(to: x0, from: scalarSize..<(2 * scalarSize))
        }
        var y1: Int16 = 0
        withUnsafeMutableBytes(of: &y1) { y1 in
            _ = data.copyBytes(to: y1, from: (2 * scalarSize)..<(3 * scalarSize))
        }
        var x1: Int16 = 0
        withUnsafeMutableBytes(of: &x1) { x1 in
            _ = data.copyBytes(to: x1, from: (3 * scalarSize)..<(4 * scalarSize))
        }
        
        return CGRect(x: CGFloat(x0), y: CGFloat(y0), width: CGFloat(x1 - x0), height: CGFloat(y1 - y0))
    }
    
    public convenience init(rgbColor: RGBColor) {
        var data = Data(capacity: 3)
        data.append(rgbColor.r)
        data.append(rgbColor.g)
        data.append(rgbColor.b)
        self.init(type: .rgbColor, data: data)
    }
    public var rgbColorValue: RGBColor? {
        guard let color = coerce(to: .rgbColor) else {
            return nil
        }
        
        let data = color.data
        let scalarSize = MemoryLayout<UInt16>.size
        
        var r: UInt16 = 0
        withUnsafeMutableBytes(of: &r) { r in
            _ = data.copyBytes(to: r, from: 0..<scalarSize)
        }
        var g: UInt16 = 0
        withUnsafeMutableBytes(of: &g) { g in
            _ = data.copyBytes(to: g, from: scalarSize..<(2 * scalarSize))
        }
        var b: UInt16 = 0
        withUnsafeMutableBytes(of: &b) { b in
            _ = data.copyBytes(to: b, from: (2 * scalarSize)..<(3 * scalarSize))
        }
        
        return RGBColor(r: r, g: g, b: b)
    }
    
    public static override func currentProcess() -> AEDescriptor {
        AEDescriptor(NSAppleEventDescriptor.currentProcess())
    }
    public convenience init(processIdentifier: pid_t) {
        self.init(NSAppleEventDescriptor(processIdentifier: processIdentifier))
    }
    public convenience init(applicationURL: URL) {
        self.init(NSAppleEventDescriptor(applicationURL: applicationURL))
    }

    public convenience init(eventClass: AEEventClass, eventID: AEEventID, target: AEDescriptor?, returnID: AEReturnID = .auto, transactionID: AETransactionID = .any) {
        self.init(NSAppleEventDescriptor(eventClass: eventClass, eventID: eventID, targetDescriptor: target, returnID: returnID, transactionID: transactionID))
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public static func record(type: AE4.AEType = .record, _ kv: KeyValuePairs<AE4, AEDescriptor> = [:]) -> AEDescriptor? {
        guard let record = self.record().coerce(to: type) else {
            return nil
        }
        record.add(kv)
        return record
    }
    
    public static var appRoot: AEDescriptor {
        .null()
    }
    public static var containerRoot: AEDescriptor {
        AEDescriptor(type: .currentContainer, data: nil)
    }
    public static var specimenRoot: AEDescriptor {
        AEDescriptor(type: .objectBeingExamined, data: nil)
    }
    
    public func coerce(to type: AE4.AEType) -> AEDescriptor? {
        coerce(toDescriptorType: type.rawValue).map(AEDescriptor.init)
    }
    
    public subscript(_ keyword: AE4) -> AEDescriptor? {
        get {
            paramDescriptor(forKeyword: keyword).map(AEDescriptor.init)
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
    
    public func append(_ descriptor: AEDescriptor) {
        insert(descriptor, at: 0)
    }
    
    public subscript(attribute: AE4.Attribute) -> AEDescriptor? {
        get {
            attributeDescriptor(forKeyword: attribute.rawValue).map(AEDescriptor.init)
        }
        set {
            if let newValue = newValue {
                setAttribute(newValue, forKeyword: attribute.rawValue)
            } else {
                preconditionFailure("Cannot set attribute to nil")
            }
        }
    }
    
    public var allKeys: Set<AE4> {
        var keys: Set<AE4> = []
        for i in 1...numberOfItems {
            keys.insert(keywordForDescriptor(at: i))
        }
        return keys
    }
    
    public override func atIndex(_ index: Int) -> AEDescriptor? {
        super.atIndex(index).map(AEDescriptor.init)
    }
    
    public override func sendEvent(options sendOptions: SendOptions = [], timeout timeoutInSeconds: TimeInterval) throws -> AEDescriptor {
        AEDescriptor(try super.sendEvent(options: sendOptions, timeout: timeoutInSeconds))
    }
    
}

extension AEDescriptor: Codable, AETyped {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
    
    public convenience init(from decoder: Decoder) throws {
        guard let descriptor = decoder.userInfo[.descriptor] as? AEDescriptor else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Can only decode an AEDescriptor from an AEDescriptor"))
        }
        self.init(type: descriptor.type, data: descriptor.data)
    }
    
    public var aeType: AE4.AEType {
        type
    }
    
}
