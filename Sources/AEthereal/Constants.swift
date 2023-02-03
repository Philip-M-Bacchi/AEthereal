//  Originally written by hhas.
//  See README.md for licensing information.

import CoreServices.AE.AEDataModel
import Darwin.MacTypes

public typealias AE4 = OSType

extension AE4 {
    
    public enum Descriptors {
    }
    
    public enum Classes {
    }
    
    public enum Enumerators {
    }
    
    public enum IndexForm: AE4, CaseIterable, Codable, AETyped {
        
        case absolutePosition = 0x696E6478
        case name = 0x6E616D65
        case propertyID = 0x70726F70
        case range = 0x72616E67
        case relativePosition = 0x72656C65
        case test = 0x74657374
        case uniqueID = 0x49442020
        case userPropertyID = 0x75737270
        
    }
    
    public enum LogicalOperator: AE4, CaseIterable, Codable, AETyped {
        
        case and = 0x414e4420
        case or = 0x4f522020
        case not = 0x4e4f5420
        
    }
    
    public enum Comparison: AE4, CaseIterable, Codable, AETyped {
        
        case lessThan = 0x3c202020
        case lessThanEquals = 0x3c3d2020
        case greaterThan = 0x3e202020
        case greaterThanEquals = 0x3e3d2020
        case equals = 0x3d202020
        
        case contains = 0x636f6e74
        case beginsWith = 0x62677774
        case endsWith = 0x656e6473
        
    }
    
    public enum AbsoluteOrdinal: AE4, CaseIterable, Codable, AETyped {
        
        case first = 0x66697273
        case last = 0x6c617374
        case middle = 0x6d696464
        case random = 0x616e7920
        case all = 0x616c6c20
        
        public var aeType: AE4.AEType {
            .absoluteOrdinal
        }
        
    }
    
    public enum RelativeOrdinal: AE4, CaseIterable, Codable, AETyped {
        
        case next = 0x6e657874
        case previous = 0x70726576
        
    }
    
    public enum InsertionLocation: AE4, CaseIterable, Codable, AETyped {
        
        case beginning = 0x62676E67
        case end = 0x656E6420
        case before = 0x6265666F
        case after = 0x61667465
        
    }
    
    public enum TestPredicateKeywords {
    }
    
    public enum ObjectSpecifierKeywords {
    }
    
    public enum RangeSpecifierKeywords {
    }
    
    public enum InsertionSpecifierKeywords {
    }
    
    public enum Considerations {
    }
    
    public enum Suites {
    }
    
    public enum AESymbols {
    }
    
    public enum ASSymbols {
    }
    
    public enum ASOSASymbols {
    }
    
    public enum Keywords {
    }
    
    public enum Attribute: AE4, CaseIterable {
        
        case eventClass = 0x6576636C
        case eventID = 0x65766964
        case eventSource = 0x65737263
        case interactLevel = 0x696E7465
        case replyPort = 0x72657070
        case replyRequested = 0x72657071
        case returnID = 0x72746964
        case subject = 0x7375626A
        case timeout = 0x74696D6F
        case transactionID = 0x7472616E
        case considsAndIgnores = 0x63736967
        
    }
    
    public enum Events {
    }
    
    public enum OSAErrorKeywords {
    }
    
    public enum OSASymbols {
    }
    
    public enum ASKeywords {
    }
    
    public enum Properties {
    }
    
    public enum ASProperties {
    }
    
    public struct AEType: RawRepresentable, Hashable, Codable, AETyped {
        
        public typealias RawValue = AE4
        
        public init(rawValue: AE4) {
            self.rawValue = rawValue
        }
        
        public var rawValue: AE4
        
        public var aeType: AE4.AEType {
            .type
        }
        
        public static let _128BitFloatingPoint = AEType(rawValue: 0x6C64626C)
        public static let list = AEType(rawValue: 0x6C697374)
        public static let record = AEType(rawValue: 0x7265636F)
        public static let aete = AEType(rawValue: 0x61657465)
        public static let aeText = AEType(rawValue: 0x74545854)
        public static let aeut = AEType(rawValue: 0x61657574)
        public static let absoluteOrdinal = AEType(rawValue: 0x6162736F)
        public static let alias = AEType(rawValue: 0x616C6973)
        public static let appParameters = AEType(rawValue: 0x61707061)
        public static let applSignature = AEType(rawValue: 0x7369676E)
        public static let appleEvent = AEType(rawValue: 0x61657674)
        public static let appleScript = AEType(rawValue: 0x61736372)
        public static let applicationBundleID = AEType(rawValue: 0x62756E64)
        public static let applicationURL = AEType(rawValue: 0x6170726C)
        public static let best = AEType(rawValue: 0x62657374)
        public static let bookmarkData = AEType(rawValue: 0x626D726B)
        public static let boolean = AEType(rawValue: 0x626F6F6C)
        public static let cfAbsoluteTime = AEType(rawValue: 0x63666174)
        public static let cfArrayRef = AEType(rawValue: 0x63666172)
        public static let cfAttributedStringRef = AEType(rawValue: 0x63666173)
        public static let cfBooleanRef = AEType(rawValue: 0x63667466)
        public static let cfDictionaryRef = AEType(rawValue: 0x63666463)
        public static let cfMutableArrayRef = AEType(rawValue: 0x63666D61)
        public static let cfMutableAttributedStringRef = AEType(rawValue: 0x63666161)
        public static let cfMutableDictionaryRef = AEType(rawValue: 0x63666D64)
        public static let cfMutableStringRef = AEType(rawValue: 0x63666D73)
        public static let cfNumberRef = AEType(rawValue: 0x63666E62)
        public static let cfStringRef = AEType(rawValue: 0x63667374)
        public static let cfTypeRef = AEType(rawValue: 0x63667479)
        public static let cString = AEType(rawValue: 0x63737472)
        public static let centimeters = AEType(rawValue: 0x636D7472)
        public static let compDescriptor = AEType(rawValue: 0x636D7064)
        public static let componentInstance = AEType(rawValue: 0x636D7069)
        public static let cubicCentimeter = AEType(rawValue: 0x63636D74)
        public static let cubicFeet = AEType(rawValue: 0x63666574)
        public static let cubicInches = AEType(rawValue: 0x6375696E)
        public static let cubicMeters = AEType(rawValue: 0x636D6574)
        public static let cubicYards = AEType(rawValue: 0x63797264)
        public static let currentContainer = AEType(rawValue: 0x63636E74)
        public static let data = AEType(rawValue: 0x74647461)
        public static let decimalStruct = AEType(rawValue: 0x6465636D)
        public static let degreesC = AEType(rawValue: 0x64656763)
        public static let degreesF = AEType(rawValue: 0x64656766)
        public static let degreesK = AEType(rawValue: 0x6465676B)
        public static let elemInfo = AEType(rawValue: 0x656C696E)
        public static let enumerated = AEType(rawValue: 0x656E756D)
        public static let eventInfo = AEType(rawValue: 0x6576696E)
        public static let eventRecord = AEType(rawValue: 0x65767263)
        public static let eventRef = AEType(rawValue: 0x65767266)
        public static let fsRef = AEType(rawValue: 0x66737266)
        public static let fss = AEType(rawValue: 0x66737320)
        public static let `false` = AEType(rawValue: 0x66616C73)
        public static let feet = AEType(rawValue: 0x66656574)
        public static let fileURL = AEType(rawValue: 0x6675726C)
        public static let finderWindow = AEType(rawValue: 0x6677696E)
        public static let fixed = AEType(rawValue: 0x66697864)
        public static let fixedPoint = AEType(rawValue: 0x66706E74)
        public static let fixedRectangle = AEType(rawValue: 0x66726374)
        public static let gif = AEType(rawValue: 0x47494666)
        public static let gallons = AEType(rawValue: 0x67616C6E)
        public static let grams = AEType(rawValue: 0x6772616D)
        public static let ieee32BitFloatingPoint = AEType(rawValue: 0x73696E67)
        public static let ieee64BitFloatingPoint = AEType(rawValue: 0x646F7562)
        public static let iso8601DateTime = AEType(rawValue: 0x69736F74)
        public static let inches = AEType(rawValue: 0x696E6368)
        public static let indexDescriptor = AEType(rawValue: 0x696E6465)
        public static let insertionLoc = AEType(rawValue: 0x696E736C)
        public static let intlText = AEType(rawValue: 0x69747874)
        public static let intlWritingCode = AEType(rawValue: 0x696E746C)
        public static let jpeg = AEType(rawValue: 0x4A504547)
        public static let kernelProcessID = AEType(rawValue: 0x6B706964)
        public static let keyword = AEType(rawValue: 0x6B657977)
        public static let kilograms = AEType(rawValue: 0x6B67726D)
        public static let kilometers = AEType(rawValue: 0x6B6D7472)
        public static let liters = AEType(rawValue: 0x6C697472)
        public static let logicalDescriptor = AEType(rawValue: 0x6C6F6769)
        public static let longDateTime = AEType(rawValue: 0x6C647420)
        public static let longFixed = AEType(rawValue: 0x6C667864)
        public static let longFixedPoint = AEType(rawValue: 0x6C667074)
        public static let longFixedRectangle = AEType(rawValue: 0x6C667263)
        public static let longPoint = AEType(rawValue: 0x6C706E74)
        public static let longRectangle = AEType(rawValue: 0x6C726374)
        public static let machPort = AEType(rawValue: 0x706F7274)
        public static let machineLoc = AEType(rawValue: 0x6D4C6F63)
        public static let meters = AEType(rawValue: 0x6D657472)
        public static let miles = AEType(rawValue: 0x6D696C65)
        public static let missingValue = AEType(rawValue: 0x6D736E67)
        public static let null = AEType(rawValue: 0x6E756C6C)
        public static let osaErrorRange = AEType(rawValue: 0x65726E67)
        public static let objectBeingExamined = AEType(rawValue: 0x65786D6E)
        public static let objectSpecifier = AEType(rawValue: 0x6F626A20)
        public static let offsetArray = AEType(rawValue: 0x6F666179)
        public static let ounces = AEType(rawValue: 0x6F7A7320)
        public static let pString = AEType(rawValue: 0x70737472)
        public static let paramInfo = AEType(rawValue: 0x706D696E)
        public static let pict = AEType(rawValue: 0x50494354)
        public static let pounds = AEType(rawValue: 0x6C627320)
        public static let processSerialNumber = AEType(rawValue: 0x70736E20)
        public static let propInfo = AEType(rawValue: 0x70696E66)
        public static let property = AEType(rawValue: 0x70726F70)
        public static let ptr = AEType(rawValue: 0x70747220)
        public static let quarts = AEType(rawValue: 0x71727473)
        public static let qdPoint = AEType(rawValue: 0x51447074)
        public static let qdRectangle = AEType(rawValue: 0x71647274)
        public static let rgbColor = AEType(rawValue: 0x63524742)
        public static let rangeDescriptor = AEType(rawValue: 0x72616E67)
        public static let rectangle = AEType(rawValue: 0x63726563)
        public static let relativeDescriptor = AEType(rawValue: 0x72656C20)
        public static let roundedRectangle = AEType(rawValue: 0x63727263)
        public static let row = AEType(rawValue: 0x63726F77)
        public static let sInt16 = AEType(rawValue: 0x73686F72)
        public static let sInt32 = AEType(rawValue: 0x6C6F6E67)
        public static let sInt64 = AEType(rawValue: 0x636F6D70)
        public static let script = AEType(rawValue: 0x73637074)
        public static let sound = AEType(rawValue: 0x736E6420)
        public static let squareFeet = AEType(rawValue: 0x73716674)
        public static let squareKilometers = AEType(rawValue: 0x73716B6D)
        public static let squareMeters = AEType(rawValue: 0x7371726D)
        public static let squareMiles = AEType(rawValue: 0x73716D69)
        public static let squareYards = AEType(rawValue: 0x73717964)
        public static let styledText = AEType(rawValue: 0x53545854)
        public static let styledUnicodeText = AEType(rawValue: 0x73757478)
        public static let tiff = AEType(rawValue: 0x54494646)
        public static let table = AEType(rawValue: 0x6374626C)
        public static let text = AEType(rawValue: 0x54455854)
        public static let textRange = AEType(rawValue: 0x7478726E)
        public static let textRangeArray = AEType(rawValue: 0x74726179)
        public static let textStyles = AEType(rawValue: 0x74737479)
        public static let token = AEType(rawValue: 0x746F6B65)
        public static let `true` = AEType(rawValue: 0x74727565)
        public static let type = AEType(rawValue: 0x74797065)
        public static let uInt16 = AEType(rawValue: 0x75736872)
        public static let uInt32 = AEType(rawValue: 0x6D61676E)
        public static let uInt64 = AEType(rawValue: 0x75636F6D)
        public static let utf16ExternalRepresentation = AEType(rawValue: 0x75743136)
        public static let utf8Text = AEType(rawValue: 0x75746638)
        public static let unicodeText = AEType(rawValue: 0x75747874)
        public static let version = AEType(rawValue: 0x76657273)
        public static let whoseDescriptor = AEType(rawValue: 0x77686F73)
        public static let whoseRange = AEType(rawValue: 0x77726E67)
        public static let wildCard = AEType(rawValue: 0x2A2A2A2A)
        public static let yards = AEType(rawValue: 0x79617264)
        
    }
    
    public struct AEEnum: RawRepresentable, Hashable, Codable, AETyped {
        
        public typealias RawValue = AE4
        
        public init(rawValue: AE4) {
            self.rawValue = rawValue
        }
        
        public var rawValue: AE4
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(rawValue: try container.decode(AE4.self))
        }
        
    }
    
}

extension AE4 {
    
    // Not defined in OpenScripting.h for some reason:
    static let inheritedProperties: AE4 = 0x6340235e // 'c@#^'
    
}

extension AEReturnID {
    
    /// AECreateAppleEvent: Generate an ID unique to the current session.
    public static let auto: AEReturnID = -1 // Int16
    
}

extension AETransactionID {
    
    /// AECreateAppleEvent: Not part of a transaction.
    public static let any: AETransactionID = 0 // Int32
    
}

/******************************************************************************/
// MARK: AE4 symbols
// Note: Swift wrongly maps some of the original constant types to Int instead of AE4/UInt32.
//       Use these instead.

extension AE4.Classes {
    
    static let application: AE4 = 0x63617070
    static let april: AE4 = 0x61707220
    static let august: AE4 = 0x61756720
    static let boolean: AE4 = 0x626F6F6C
    static let char: AE4 = 0x63686120
    static let classIdentifier: AE4 = 0x70636C73
    static let closure: AE4 = 0x636C7372
    static let coerceLowerCase: AE4 = 0x74786C6F
    static let coerceOneByteToTwoByte: AE4 = 0x74786578
    static let coerceRemoveDiacriticals: AE4 = 0x74786463
    static let coerceRemoveHyphens: AE4 = 0x74786879
    static let coerceRemovePunctuation: AE4 = 0x74787063
    static let coerceRemoveWhiteSpace: AE4 = 0x74787773
    static let coerceUpperCase: AE4 = 0x74787570
    static let coercion: AE4 = 0x636F6563
    static let column: AE4 = 0x63636F6C
    static let constant: AE4 = 0x656E756D
    static let december: AE4 = 0x64656320
    static let document: AE4 = 0x646F6375
    static let drawingArea: AE4 = 0x63647277
    static let enumeration: AE4 = 0x656E756D
    static let eventIdentifier: AE4 = 0x65766E74
    static let february: AE4 = 0x66656220
    static let file: AE4 = 0x66696C65
    static let fixed: AE4 = 0x66697864
    static let fixedPoint: AE4 = 0x66706E74
    static let fixedRectangle: AE4 = 0x66726374
    static let friday: AE4 = 0x66726920
    static let html: AE4 = 0x68746D6C
    static let handleBreakpoint: AE4 = 0x6272616B
    static let handler: AE4 = 0x68616E64
    static let insertionLoc: AE4 = 0x696E736C
    static let insertionPoint: AE4 = 0x63696E73
    static let intlText: AE4 = 0x69747874
    static let intlWritingCode: AE4 = 0x696E746C
    static let item: AE4 = 0x6369746D
    static let january: AE4 = 0x6A616E20
    static let july: AE4 = 0x6A756C20
    static let june: AE4 = 0x6A756E20
    static let keyForm: AE4 = 0x6B66726D
    static let keyIdentifier: AE4 = 0x6B796964
    static let keystroke: AE4 = 0x6B707273
    static let line: AE4 = 0x636C696E
    static let linkedList: AE4 = 0x6C6C7374
    static let list: AE4 = 0x6C697374
    static let listElement: AE4 = 0x63656C6D
    static let listOrRecord: AE4 = 0x6C722020
    static let listOrString: AE4 = 0x6C732020
    static let listRecordOrString: AE4 = 0x6C727320
    static let longDateTime: AE4 = 0x6C647420
    static let longFixed: AE4 = 0x6C667864
    static let longFixedPoint: AE4 = 0x6C667074
    static let longFixedRectangle: AE4 = 0x6C667263
    static let longPoint: AE4 = 0x6C706E74
    static let longRectangle: AE4 = 0x6C726374
    static let machine: AE4 = 0x6D616368
    static let machineLoc: AE4 = 0x6D4C6F63
    static let march: AE4 = 0x6D617220
    static let may: AE4 = 0x6D617920
    static let missingValue: AE4 = 0x6D736E67
    static let monday: AE4 = 0x6D6F6E20
    static let month: AE4 = 0x6D6E7468
    static let november: AE4 = 0x6E6F7620
    static let number: AE4 = 0x6E6D6272
    static let numberDateTimeOrString: AE4 = 0x6E647320
    static let numberOrDateTime: AE4 = 0x6E642020
    static let numberOrString: AE4 = 0x6E732020
    static let object: AE4 = 0x636F626A
    static let objectBeingExamined: AE4 = 0x65786D6E
    static let objectSpecifier: AE4 = 0x6F626A20
    static let october: AE4 = 0x6F637420
    static let openableObject: AE4 = 0x636F6F62
    static let pict: AE4 = 0x50494354
    static let preposition: AE4 = 0x70726570
    static let procedure: AE4 = 0x70726F63
    static let property: AE4 = 0x70726F70
    static let rawData: AE4 = 0x72646174
    static let real: AE4 = 0x646F7562
    static let record: AE4 = 0x7265636F
    static let rectangle: AE4 = 0x63726563
    static let reference: AE4 = 0x6F626A20
    static let rotation: AE4 = 0x74726F74
    static let row: AE4 = 0x63726F77
    static let saturday: AE4 = 0x73617420
    static let script: AE4 = 0x73637074
    static let seconds: AE4 = 0x73636E64
    static let selection: AE4 = 0x6373656C
    static let september: AE4 = 0x73657020
    static let smallReal: AE4 = 0x73696E67
    static let storage: AE4 = 0x73746F72
    static let string: AE4 = 0x54455854
    static let stringClass: AE4 = 0x54455854
    static let sunday: AE4 = 0x73756E20
    static let symbol: AE4 = 0x73796D62
    static let table: AE4 = 0x6374626C
    static let text: AE4 = 0x63747874
    static let thursday: AE4 = 0x74687520
    static let tuesday: AE4 = 0x74756520
    static let type: AE4 = 0x74797065
    static let url: AE4 = 0x75726C20
    static let undefined: AE4 = 0x756E6466
    static let userIdentifier: AE4 = 0x75696420
    static let vector: AE4 = 0x76656374
    static let version: AE4 = 0x76657273
    static let wednesday: AE4 = 0x77656420
    static let weekday: AE4 = 0x776B6479
    static let window: AE4 = 0x6377696E
    static let word: AE4 = 0x63776F72
    static let writingCodeInfo: AE4 = 0x6369746C
    static let zone: AE4 = 0x7A6F6E65
    
}

extension AE4.Enumerators {
    
    static let capsLockDown: AE4 = 0x4B636C6B
    static let clearKey: AE4 = 0x6B734700
    static let commandDown: AE4 = 0x4B636D64
    static let controlDown: AE4 = 0x4B63746C
    static let deleteKey: AE4 = 0x6B733300
    static let downArrowKey: AE4 = 0x6B737D00
    static let endKey: AE4 = 0x6B737700
    static let enterKey: AE4 = 0x6B734C00
    static let escapeKey: AE4 = 0x6B733500
    static let f10Key: AE4 = 0x6B736D00
    static let f11Key: AE4 = 0x6B736700
    static let f12Key: AE4 = 0x6B736F00
    static let f13Key: AE4 = 0x6B736900
    static let f14Key: AE4 = 0x6B736B00
    static let f15Key: AE4 = 0x6B737100
    static let f1Key: AE4 = 0x6B737A00
    static let f2Key: AE4 = 0x6B737800
    static let f3Key: AE4 = 0x6B736300
    static let f4Key: AE4 = 0x6B737600
    static let f5Key: AE4 = 0x6B736000
    static let f6Key: AE4 = 0x6B736100
    static let f7Key: AE4 = 0x6B736200
    static let f8Key: AE4 = 0x6B736400
    static let f9Key: AE4 = 0x6B736500
    static let forwardDelKey: AE4 = 0x6B737500
    static let helpKey: AE4 = 0x6B737200
    static let homeKey: AE4 = 0x6B737300
    static let keyKind: AE4 = 0x656B7374
    static let leftArrowKey: AE4 = 0x6B737B00
    static let modifiers: AE4 = 0x654D6473
    static let optionDown: AE4 = 0x4B6F7074
    static let pageDownKey: AE4 = 0x6B737900
    static let pageUpKey: AE4 = 0x6B737400
    static let pointingDevice: AE4 = 0x65647064
    static let returnKey: AE4 = 0x6B732400
    static let rightArrowKey: AE4 = 0x6B737C00
    static let scheme: AE4 = 0x65736368
    static let shiftDown: AE4 = 0x4B736674
    static let tabKey: AE4 = 0x6B733000
    static let upArrowKey: AE4 = 0x6B737E00
    static let urlAFP: AE4 = 0x61667020
    static let urlAT: AE4 = 0x61742020
    static let urlEPPC: AE4 = 0x65707063
    static let urlFTP: AE4 = 0x66747020
    static let urlFile: AE4 = 0x66696C65
    static let urlGopher: AE4 = 0x67706872
    static let urlHTTP: AE4 = 0x68747470
    static let urlHTTPS: AE4 = 0x68747073
    static let urlIMAP: AE4 = 0x696D6170
    static let urlLDAP: AE4 = 0x756C6470
    static let urlLaunch: AE4 = 0x6C61756E
    static let urlMail: AE4 = 0x6D61696C
    static let urlMailbox: AE4 = 0x6D626F78
    static let urlMessage: AE4 = 0x6D657373
    static let urlMulti: AE4 = 0x6D756C74
    static let urlNFS: AE4 = 0x756E6673
    static let urlNNTP: AE4 = 0x6E6E7470
    static let urlNews: AE4 = 0x6E657773
    static let urlPOP: AE4 = 0x75706F70
    static let urlRTSP: AE4 = 0x72747370
    static let urlSNews: AE4 = 0x736E7773
    static let urlTelnet: AE4 = 0x746C6E74
    static let urlUnknown: AE4 = 0x75726C3F
    
}

extension AE4.TestPredicateKeywords {
    
    static let comparisonOperator: AE4 = 0x72656c6f
    static let firstObject: AE4 = 0x6f626a31
    static let secondObject: AE4 = 0x6f626a32
    
    static let logicalOperator: AE4 = 0x6c6f6763
    static let logicalTerms: AE4 = 0x7465726d
    
}

extension AE4.ObjectSpecifierKeywords {
    
    static let desiredClass: AE4 = 0x77616e74
    static let container: AE4 = 0x66726f6d
    static let keyForm: AE4 = 0x666f726d
    static let keyData: AE4 = 0x73656c64
    
}

extension AE4.RangeSpecifierKeywords {
    
    static let start: AE4 = 0x73746172
    static let stop: AE4 = 0x73746f70
    
}

extension AE4.InsertionSpecifierKeywords {

    static let object: AE4 = 0x6B6F626A
    static let position: AE4 = 0x6B706F73
    
}

extension AE4.Considerations {

    static let `case`: AE4 = 0x63617365
    static let diacritic: AE4 = 0x64696163
    static let whiteSpace: AE4 = 0x77686974
    static let hyphens: AE4 = 0x68797068
    static let expansion: AE4 = 0x65787061
    static let punctuation: AE4 = 0x70756E63
    static let numericStrings: AE4 = 0x6E756D65
    
}

extension AE4.AESymbols {
    
    static let about: AE4 = 0x61626F75
    static let activate: AE4 = 0x61637476
    static let aliasSelection: AE4 = 0x73616C69
    static let all: AE4 = 0x616C6C20
    static let allCaps: AE4 = 0x616C6370
    static let any: AE4 = 0x616E7920
    static let applicationClass: AE4 = 0x6170706C
    static let applicationDied: AE4 = 0x6F626974
    static let ask: AE4 = 0x61736B20
    static let autoDown: AE4 = 0x6175746F
    static let beginsWith: AE4 = 0x62677774
    static let bold: AE4 = 0x626F6C64
    static let caseSensEquals: AE4 = 0x63736571
    static let centered: AE4 = 0x63656E74
    static let changeView: AE4 = 0x76696577
    static let clone: AE4 = 0x636C6F6E
    static let close: AE4 = 0x636C6F73
    static let commandClass: AE4 = 0x636D6E64
    static let condensed: AE4 = 0x636F6E64
    static let contains: AE4 = 0x636F6E74
    static let copy: AE4 = 0x636F7079
    static let countElements: AE4 = 0x636E7465
    static let createElement: AE4 = 0x6372656C
    static let cut: AE4 = 0x63757420
    static let deactivate: AE4 = 0x64616374
    static let delete: AE4 = 0x64656C6F
    static let doObjectsExist: AE4 = 0x646F6578
    static let doScript: AE4 = 0x646F7363
    static let down: AE4 = 0x646F776E
    static let drag: AE4 = 0x64726167
    static let duplicateSelection: AE4 = 0x73647570
    static let emptyTrash: AE4 = 0x656D7074
    static let endsWith: AE4 = 0x656E6473
    static let equals: AE4 = 0x3D202020
    static let expanded: AE4 = 0x70657870
    static let `false`: AE4 = 0x66616C73
    static let fast: AE4 = 0x66617374
    static let first: AE4 = 0x66697273
    static let getClassInfo: AE4 = 0x716F626A
    static let getData: AE4 = 0x67657464
    static let getDataSize: AE4 = 0x6473697A
    static let getInfoSelection: AE4 = 0x73696E66
    static let getPrivilegeSelection: AE4 = 0x73707276
    static let greaterThan: AE4 = 0x3E202020
    static let greaterThanEquals: AE4 = 0x3E3D2020
    static let grow: AE4 = 0x67726F77
    static let hidden: AE4 = 0x6869646E
    static let highLevel: AE4 = 0x68696768
    static let isUniform: AE4 = 0x6973756E
    static let keyClass: AE4 = 0x6B657963
    static let keyDown: AE4 = 0x6B64776E
    static let last: AE4 = 0x6C617374
    static let logOut: AE4 = 0x6C6F676F
    static let lowercase: AE4 = 0x6C6F7763
    static let makeObjectsVisible: AE4 = 0x6D766973
    static let middle: AE4 = 0x6D696464
    static let modifiable: AE4 = 0x6D6F6466
    static let mouseClass: AE4 = 0x6D6F7573
    static let mouseDown: AE4 = 0x6D64776E
    static let mouseDownInBack: AE4 = 0x6D64626B
    static let move: AE4 = 0x6D6F7665
    static let moved: AE4 = 0x6D6F7665
    static let navigationKey: AE4 = 0x6E617665
    static let next: AE4 = 0x6E657874
    static let no: AE4 = 0x6E6F2020
    static let noArrow: AE4 = 0x61726E6F
    static let nonmodifiable: AE4 = 0x6E6D6F64
    static let notifyRecording: AE4 = 0x72656372
    static let notifyStartRecording: AE4 = 0x72656331
    static let notifyStopRecording: AE4 = 0x72656330
    static let `open`: AE4 = 0x6F646F63
    static let openContents: AE4 = 0x6F636F6E
    static let openDocuments: AE4 = 0x6F646F63
    static let openSelection: AE4 = 0x736F7065
    static let outline: AE4 = 0x6F75746C
    static let pageSetup: AE4 = 0x70677375
    static let paste: AE4 = 0x70617374
    static let plain: AE4 = 0x706C616E
    static let previous: AE4 = 0x70726576
    static let print: AE4 = 0x70646F63
    static let printDocuments: AE4 = 0x70646F63
    static let printSelection: AE4 = 0x73707269
    static let printWindow: AE4 = 0x7077696E
    static let promise: AE4 = 0x70726F6D
    static let quitAll: AE4 = 0x71756961
    static let quitApplication: AE4 = 0x71756974
    static let rawKey: AE4 = 0x726B6579
    static let reallyLogOut: AE4 = 0x726C676F
    static let redo: AE4 = 0x7265646F
    static let regular: AE4 = 0x7265676C
    static let reopenApplication: AE4 = 0x72617070
    static let replace: AE4 = 0x72706C63
    static let resized: AE4 = 0x7273697A
    static let restart: AE4 = 0x72657374
    static let resume: AE4 = 0x72736D65
    static let revealSelection: AE4 = 0x73726576
    static let revert: AE4 = 0x72767274
    static let save: AE4 = 0x73617665
    static let scriptingSizeResource: AE4 = 0x7363737A
    static let select: AE4 = 0x736C6374
    static let setData: AE4 = 0x73657464
    static let setPosition: AE4 = 0x706F736E
    static let shadow: AE4 = 0x73686164
    static let sharedScriptHandler: AE4 = 0x77736370
    static let showClipboard: AE4 = 0x7368636C
    static let showPreferences: AE4 = 0x70726566
    static let showRestartDialog: AE4 = 0x72727374
    static let showShutdownDialog: AE4 = 0x7273646E
    static let shutDown: AE4 = 0x73687574
    static let sleep: AE4 = 0x736C6570
    static let specialClassProperties: AE4 = 0x63402321
    static let startRecording: AE4 = 0x72656361
    static let stopRecording: AE4 = 0x72656363
    static let stoppedMoving: AE4 = 0x73746F70
    static let `subscript`: AE4 = 0x73627363
    static let suspend: AE4 = 0x73757370
    static let terminologyExtension: AE4 = 0x61657465
    static let `true`: AE4 = 0x74727565
    static let underline: AE4 = 0x756E646C
    static let undo: AE4 = 0x756E646F
    static let up: AE4 = 0x75702020
    static let update: AE4 = 0x75706474
    static let userTerminology: AE4 = 0x61657574
    static let virtualKey: AE4 = 0x6B657963
    static let wholeWordEquals: AE4 = 0x77776571
    static let windowClass: AE4 = 0x77696E64
    static let yes: AE4 = 0x79657320
    static let zoom: AE4 = 0x7A6F6F6D
    
}

extension AE4.ASSymbols {
    
    static let add: AE4 = 0x2B202020
    static let comesAfter: AE4 = 0x63616672
    static let comesBefore: AE4 = 0x63626672
    static let comment: AE4 = 0x636D6E74
    static let commentEvent: AE4 = 0x636D6E74
    static let concatenate: AE4 = 0x63636174
    static let considerReplies: AE4 = 0x726D7465
    static let contains: AE4 = 0x636F6E74
    static let currentApplication: AE4 = 0x63757261
    static let divide: AE4 = 0x2F202020
    static let endsWith: AE4 = 0x656E6473
    static let equal: AE4 = 0x3D202020
    static let errorEventCode: AE4 = 0x65727220
    static let greaterThan: AE4 = 0x3E202020
    static let greaterThanOrEqual: AE4 = 0x3E3D2020
    static let hasOpenHandler: AE4 = 0x68736F64
    static let initializeEventCode: AE4 = 0x696E6974
    static let magicEndTellEvent: AE4 = 0x74656E64
    static let magicTellEvent: AE4 = 0x74656C6C
    static let multiply: AE4 = 0x2A202020
    static let negate: AE4 = 0x6E656720
    static let prepositionalSubroutine: AE4 = 0x70736272
    static let quotient: AE4 = 0x64697620
    static let remainder: AE4 = 0x6D6F6420
    static let startLogEvent: AE4 = 0x6C6F6731
    static let startsWith: AE4 = 0x62677774
    static let stopLogEvent: AE4 = 0x6C6F6730
    static let subroutineEvent: AE4 = 0x70736272
    static let subtract: AE4 = 0x2D202020
    
}

extension AE4.Suites {
    
    static let coreSuite: AE4 = 0x636F7265
    static let getSuiteInfo: AE4 = 0x67747369
    static let internetSuite: AE4 = 0x6775726C
    static let requiredSuite: AE4 = 0x72657164
    static let tableSuite: AE4 = 0x74626C73
    static let textSuite: AE4 = 0x54455854
    static let scriptEditorSuite: AE4 = 0x546F7953
    static let asTypeNamesSuite: AE4 = 0x74706E6D
    static let osaSuite: AE4 = 0x61736372

}

extension AE4.ASOSASymbols {
    
    static let _kAppleScriptSubtype: AE4 = 0x61736372
    
}

extension AE4.Keywords {
    
    static let directObject: AE4 = 0x2D2D2D2D
    static let requestedType: AE4 = 0x72747970
    
    static let errorNumber: AE4 = 0x6572726E
    static let errorString: AE4 = 0x65727273
    static let processSerialNumber: AE4 = 0x70736E20
    
    /// "make" -> "at" parameter
    static let insertHere: AE4 = 0x696E7368
    
}

extension AE4.Events {
    
    public enum Core {
        
        static let eventClass: AE4 = 0x61657674
        
        public enum IDs {
            
            /// Event ID of reply events.
            static let answer: AE4 = 0x616E7372
            
            static let openApplication: AE4 = 0x6F617070
            
        }
        
    }
    
    public enum Transactions {
        
        static let eventClass: AE4 = 0x6D697363
        
        public enum IDs {
            
            static let begin: AE4 = 0x62656769
            static let end: AE4 = 0x656E6474
            static let terminated: AE4 = 0x7474726D
            
        }
        
    }
    
    public enum AppleScript {

        static let eventClass: AE4 = 0x61736372
        
        public enum IDs {
            
            /// Call a user-defined AppleScript subroutine.
            static let callSubroutine: AE4 = 0x70736272
            
            /// No-op.
            static let launch: AE4 = 0x6E6F6F70
            
            /// Request app terminology in 'aete' resource format.
            /// (AETE means AppleEvent Trminology Extension.)
            static let getAETE: AE4 = 0x67647465
            /// Request AppleScript built-in terminology in 'aete' resource format.
            /// (AEUT means AppleEvent User Terminology.)
            static let getAEUT: AE4 = 0x67647574

            static let updateAETE: AE4 = 0x75647465
            static let updateAEUT: AE4 = 0x75647574
            
            /// Sent by OSA to current application with a chunk of recorded script text.
            static let recordedText: AE4 = 0x72656364
            
        }
        
        public enum Keywords {
            
            /// Name of the user-defined subroutine for callSubroutine.
            static let subroutineName: AE4 = 0x736E616D
            /// Positional subroutine arguments for callSubroutine.
            static let positionalArguments: AE4 = 0x70617267
            
            // Keywords for predefined "prepositional" subroutine parameter names.
            public enum Prepositions {
                
                static let about: AE4 = 0x61626F75
                static let above: AE4 = 0x61627665
                static let against: AE4 = 0x61677374
                static let apartFrom: AE4 = 0x61707274
                static let around: AE4 = 0x61726E64
                static let asideFrom: AE4 = 0x61736466
                static let at: AE4 = 0x61742020
                static let below: AE4 = 0x62656C77
                static let beneath: AE4 = 0x626E7468
                static let beside: AE4 = 0x62736964
                static let between: AE4 = 0x6274776E
                static let by: AE4 = 0x62792020
                static let `for`: AE4 = 0x666F7220
                static let from: AE4 = 0x66726F6D
                static let given: AE4 = 0x6769766E
                static let `in`: AE4 = 0x696E2020
                static let insteadOf: AE4 = 0x6973746F
                static let into: AE4 = 0x696E746F
                static let on: AE4 = 0x6F6E2020
                static let onto: AE4 = 0x6F6E746F
                static let outOf: AE4 = 0x6F75746F
                static let over: AE4 = 0x6F766572
                static let since: AE4 = 0x736E6365
                static let through: AE4 = 0x74686768
                static let thru: AE4 = 0x74687275
                static let to: AE4 = 0x746F2020
                static let under: AE4 = 0x756E6472
                static let until: AE4 = 0x74696C6C
                static let with: AE4 = 0x77697468
                static let without: AE4 = 0x776F7574
                
            }
            
        }
        
    }
    
    public enum DigitalHub {

        static let eventClass: AE4 = 0x64687562
        
        public enum IDs {
            
            static let blankCD: AE4 = 0x62636420
            static let blankDVD: AE4 = 0x62647664
            static let musicCD: AE4 = 0x61756364
            static let pictureCD: AE4 = 0x70696364
            static let videoDVD: AE4 = 0x76647664
            
        }
        
    }
    
    public enum FolderActions {
        
        public enum IDs {
            
            static let opened: AE4 = 0x666F706E
            static let closed: AE4 = 0x66636C6F
            static let itemsAdded: AE4 = 0x66676574
            static let itemsRemoved: AE4 = 0x666C6F73
            static let windowMoved: AE4 = 0x6673697A
            
        }
        
        public enum Keywords {
            
            /// Size of moved window.
            static let newSize: AE4 = 0x666E737A
            
        }
        
    }
    
}

extension AE4.OSAErrorKeywords {
    
    static let app: AE4 = 0x65726170
    static let args: AE4 = 0x65727261
    static let briefMessage: AE4 = 0x65727262
    static let expectedType: AE4 = 0x65727274
    static let message: AE4 = 0x65727273
    static let number: AE4 = 0x6572726E
    static let offendingObject: AE4 = 0x65726F62
    static let partialResult: AE4 = 0x70746C72
    static let range: AE4 = 0x65726E67
    
}

extension AE4.OSASymbols {
    
    static let genericScriptingComponentSubtype: AE4 = 0x73637074
    static let scriptBestType: AE4 = 0x62657374
    static let scriptIsModified: AE4 = 0x6D6F6469
    static let scriptIsTypeCompiledScript: AE4 = 0x63736372
    static let scriptIsTypeScriptContext: AE4 = 0x636E7478
    static let scriptIsTypeScriptValue: AE4 = 0x76616C75

    static let dialectCode: AE4 = 0x64636F64
    static let dialectLangCode: AE4 = 0x646C6364
    static let dialectName: AE4 = 0x646E616D
    static let dialectScriptCode: AE4 = 0x64736364
    static let sourceEnd: AE4 = 0x73726365
    static let sourceStart: AE4 = 0x73726373
    
}

extension AE4.ASKeywords {

    static let userRecordFields: AE4 = 0x75737266
    
}

extension AE4.Properties {
    
    static let bestType: AE4 = 0x70627374
    static let bounds: AE4 = 0x70626E64
    static let `class`: AE4 = 0x70636C73
    static let clipboard: AE4 = 0x70636C69
    static let color: AE4 = 0x636F6C72
    static let contents: AE4 = 0x70636E74
    static let defaultType: AE4 = 0x64656674
    static let enabled: AE4 = 0x656E626C
    static let endPoint: AE4 = 0x70656E64
    static let font: AE4 = 0x666F6E74
    static let hasCloseBox: AE4 = 0x68636C62
    static let hasTitleBar: AE4 = 0x70746974
    static let id: AE4 = 0x49442020
    static let index: AE4 = 0x70696478
    static let inherits: AE4 = 0x6340235E
    static let insertionLoc: AE4 = 0x70696E73
    static let isFloating: AE4 = 0x6973666C
    static let isFrontProcess: AE4 = 0x70697366
    static let isModal: AE4 = 0x706D6F64
    static let isModified: AE4 = 0x696D6F64
    static let isResizable: AE4 = 0x7072737A
    static let isStationeryPad: AE4 = 0x70737064
    static let isZoomable: AE4 = 0x69737A6D
    static let isZoomed: AE4 = 0x707A756D
    static let itemNumber: AE4 = 0x69746D6E
    static let keyKind: AE4 = 0x6B6B6E64
    static let keystrokeKey: AE4 = 0x6B4D7367
    static let langCode: AE4 = 0x706C6364
    static let length: AE4 = 0x6C656E67
    static let name: AE4 = 0x706E616D
    static let newElementLoc: AE4 = 0x706E656C
    static let path: AE4 = 0x46545063
    static let properties: AE4 = 0x70414C4C
    static let protection: AE4 = 0x7070726F
    static let rest: AE4 = 0x72657374
    static let reverse: AE4 = 0x72767365
    static let script: AE4 = 0x73637074
    static let scriptCode: AE4 = 0x70736364
    static let scriptTag: AE4 = 0x70736374
    static let selected: AE4 = 0x73656C63
    static let selection: AE4 = 0x73656C65
    static let textItemDelimiters: AE4 = 0x7478646C
    static let url: AE4 = 0x7055524C
    static let version: AE4 = 0x76657273
    static let visible: AE4 = 0x70766973
    
}

extension AE4.ASProperties {
    
    static let dateString: AE4 = 0x64737472
    static let day: AE4 = 0x64617920
    static let days: AE4 = 0x64617973
    static let hours: AE4 = 0x686F7572
    static let it: AE4 = 0x69742020
    static let me: AE4 = 0x6D652020
    static let minutes: AE4 = 0x6D696E20
    static let month: AE4 = 0x6D6E7468
    static let parent: AE4 = 0x70617265
    static let pi: AE4 = 0x70692020
    static let printDepth: AE4 = 0x70726470
    static let printLength: AE4 = 0x70726C6E
    static let quote: AE4 = 0x71756F74
    static let result: AE4 = 0x72736C74
    static let `return`: AE4 = 0x72657420
    static let seconds: AE4 = 0x73656373
    static let space: AE4 = 0x73706163
    static let tab: AE4 = 0x74616220
    static let time: AE4 = 0x74696D65
    static let timeString: AE4 = 0x74737472
    static let topLevelScript: AE4 = 0x61736372
    static let weekday: AE4 = 0x776B6479
    static let weeks: AE4 = 0x7765656B
    static let year: AE4 = 0x79656172
    
}
