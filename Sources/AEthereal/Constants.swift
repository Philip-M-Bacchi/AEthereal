//  Originally written by hhas.
//  See README.md for licensing information.

import Darwin.MacTypes
import Foundation.NSAppleEventDescriptor

public enum AE4 {
    
    public enum Descriptors {
    }
    
    public enum Classes {
    }
    
    public enum Enumerators {
    }
    
    public enum IndexForm: OSType, CaseIterable {
        
        case absolutePosition = 0x696E6478
        case name = 0x6E616D65
        case propertyID = 0x70726F70
        case range = 0x72616E67
        case relativePosition = 0x72656C65
        case test = 0x74657374
        case uniqueID = 0x49442020
        case userPropertyID = 0x75737270
        case whose = 0x77686F73
        
    }
    
    public enum LogicalOperator: OSType, CaseIterable {
        
        case and = 0x414e4420
        case or = 0x4f522020
        case not = 0x4e4f5420
        
    }
    
    public enum Comparison: OSType, CaseIterable {
        
        case lessThan = 0x3c202020
        case lessThanEquals = 0x3c3d2020
        case greaterThan = 0x3e202020
        case greaterThanEquals = 0x3e3d2020
        case equals = 0x3d202020
        
    }
    
    public enum Containment: OSType, CaseIterable {
        
        case contains = 0x636f6e74
        case beginsWith = 0x62677774
        case endsWith = 0x656e6473
        
    }
    
    public enum AbsoluteOrdinal: OSType, CaseIterable {
        
        case first = 0x66697273
        case last = 0x6c617374
        case middle = 0x6d696464
        case random = 0x616e7920
        case all = 0x616c6c20
    }
    
    public enum RelativeOrdinal: OSType, CaseIterable {
        
        case next = 0x6e657874
        case previous = 0x70726576
        
    }
    
    public enum InsertionLocation: OSType, CaseIterable {
        
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
    
    public enum Attributes {
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
    
    public enum Types {
    }
    
    
}

extension AE4 {
    
    /// AECreateAppleEvent: Generate an ID unique to the current session.
    static let autoGenerateReturnID: AEReturnID = -1 // Int16
    /// AECreateAppleEvent: Not part of a transaction.
    static let anyTransactionID: AETransactionID = 0 // Int32
    
    // Not defined in OpenScripting.h for some reason:

    static let inheritedProperties: OSType = 0x6340235e // 'c@#^'
    
    // AEM doesn't define codes for '!=' or 'in' operators in test clauses, so we define pseudo-codes to represent these:

    /// Encoded as `kAEEquals` + `kAENOT`.
    static let notEquals: OSType = 0x00000001
    /// Encoded as AE4. with operands reversed.
    static let isIn: OSType = 0x00000002
    
}

/******************************************************************************/
// MARK: AE4 symbols
// Note: Swift wrongly maps some of the original constant types to Int instead of OSType/UInt32.
//       Use these instead.

extension AE4.Classes {
    
    static let aeList: OSType = 0x6C697374
    static let aliasOrString: OSType = 0x73662020
    static let application: OSType = 0x63617070
    static let april: OSType = 0x61707220
    static let arc: OSType = 0x63617263
    static let august: OSType = 0x61756720
    static let boolean: OSType = 0x626F6F6C
    static let cell: OSType = 0x6363656C
    static let char: OSType = 0x63686120
    static let classIdentifier: OSType = 0x70636C73
    static let closure: OSType = 0x636C7372
    static let coerceLowerCase: OSType = 0x74786C6F
    static let coerceOneByteToTwoByte: OSType = 0x74786578
    static let coerceRemoveDiacriticals: OSType = 0x74786463
    static let coerceRemoveHyphens: OSType = 0x74786879
    static let coerceRemovePunctuation: OSType = 0x74787063
    static let coerceRemoveWhiteSpace: OSType = 0x74787773
    static let coerceUpperCase: OSType = 0x74787570
    static let coercion: OSType = 0x636F6563
    static let colorTable: OSType = 0x636C7274
    static let column: OSType = 0x63636F6C
    static let constant: OSType = 0x656E756D
    static let december: OSType = 0x64656320
    static let devSpec: OSType = 0x63646576
    static let document: OSType = 0x646F6375
    static let drawingArea: OSType = 0x63647277
    static let enumeration: OSType = 0x656E756D
    static let eventIdentifier: OSType = 0x65766E74
    static let february: OSType = 0x66656220
    static let file: OSType = 0x66696C65
    static let fixed: OSType = 0x66697864
    static let fixedPoint: OSType = 0x66706E74
    static let fixedRectangle: OSType = 0x66726374
    static let friday: OSType = 0x66726920
    static let html: OSType = 0x68746D6C
    static let handleBreakpoint: OSType = 0x6272616B
    static let handler: OSType = 0x68616E64
    static let insertionLoc: OSType = 0x696E736C
    static let insertionPoint: OSType = 0x63696E73
    static let intlText: OSType = 0x69747874
    static let intlWritingCode: OSType = 0x696E746C
    static let item: OSType = 0x6369746D
    static let january: OSType = 0x6A616E20
    static let july: OSType = 0x6A756C20
    static let june: OSType = 0x6A756E20
    static let keyForm: OSType = 0x6B66726D
    static let keyIdentifier: OSType = 0x6B796964
    static let keystroke: OSType = 0x6B707273
    static let line: OSType = 0x636C696E
    static let linkedList: OSType = 0x6C6C7374
    static let list: OSType = 0x6C697374
    static let listElement: OSType = 0x63656C6D
    static let listOrRecord: OSType = 0x6C722020
    static let listOrString: OSType = 0x6C732020
    static let listRecordOrString: OSType = 0x6C727320
    static let longDateTime: OSType = 0x6C647420
    static let longFixed: OSType = 0x6C667864
    static let longFixedPoint: OSType = 0x6C667074
    static let longFixedRectangle: OSType = 0x6C667263
    static let longInteger: OSType = 0x6C6F6E67
    static let longPoint: OSType = 0x6C706E74
    static let longRectangle: OSType = 0x6C726374
    static let machine: OSType = 0x6D616368
    static let machineLoc: OSType = 0x6D4C6F63
    static let march: OSType = 0x6D617220
    static let may: OSType = 0x6D617920
    static let missingValue: OSType = 0x6D736E67
    static let monday: OSType = 0x6D6F6E20
    static let month: OSType = 0x6D6E7468
    static let november: OSType = 0x6E6F7620
    static let number: OSType = 0x6E6D6272
    static let numberDateTimeOrString: OSType = 0x6E647320
    static let numberOrDateTime: OSType = 0x6E642020
    static let numberOrString: OSType = 0x6E732020
    static let object: OSType = 0x636F626A
    static let objectBeingExamined: OSType = 0x65786D6E
    static let objectSpecifier: OSType = 0x6F626A20
    static let october: OSType = 0x6F637420
    static let openableObject: OSType = 0x636F6F62
    static let oval: OSType = 0x636F766C
    static let pict: OSType = 0x50494354
    static let preposition: OSType = 0x70726570
    static let procedure: OSType = 0x70726F63
    static let property: OSType = 0x70726F70
    static let rawData: OSType = 0x72646174
    static let real: OSType = 0x646F7562
    static let record: OSType = 0x7265636F
    static let rectangle: OSType = 0x63726563
    static let reference: OSType = 0x6F626A20
    static let rotation: OSType = 0x74726F74
    static let row: OSType = 0x63726F77
    static let saturday: OSType = 0x73617420
    static let script: OSType = 0x73637074
    static let seconds: OSType = 0x73636E64
    static let selection: OSType = 0x6373656C
    static let september: OSType = 0x73657020
    static let shortInteger: OSType = 0x73686F72
    static let smallReal: OSType = 0x73696E67
    static let storage: OSType = 0x73746F72
    static let string: OSType = 0x54455854
    static let stringClass: OSType = 0x54455854
    static let sunday: OSType = 0x73756E20
    static let symbol: OSType = 0x73796D62
    static let table: OSType = 0x6374626C
    static let text: OSType = 0x63747874
    static let thursday: OSType = 0x74687520
    static let tuesday: OSType = 0x74756520
    static let type: OSType = 0x74797065
    static let url: OSType = 0x75726C20
    static let undefined: OSType = 0x756E6466
    static let userIdentifier: OSType = 0x75696420
    static let vector: OSType = 0x76656374
    static let version: OSType = 0x76657273
    static let wednesday: OSType = 0x77656420
    static let weekday: OSType = 0x776B6479
    static let window: OSType = 0x6377696E
    static let word: OSType = 0x63776F72
    static let writingCodeInfo: OSType = 0x6369746C
    static let zone: OSType = 0x7A6F6E65
    
}

extension AE4.Enumerators {
    
    static let capsLockDown: OSType = 0x4B636C6B
    static let clearKey: OSType = 0x6B734700
    static let commandDown: OSType = 0x4B636D64
    static let controlDown: OSType = 0x4B63746C
    static let deleteKey: OSType = 0x6B733300
    static let downArrowKey: OSType = 0x6B737D00
    static let endKey: OSType = 0x6B737700
    static let enterKey: OSType = 0x6B734C00
    static let escapeKey: OSType = 0x6B733500
    static let f10Key: OSType = 0x6B736D00
    static let f11Key: OSType = 0x6B736700
    static let f12Key: OSType = 0x6B736F00
    static let f13Key: OSType = 0x6B736900
    static let f14Key: OSType = 0x6B736B00
    static let f15Key: OSType = 0x6B737100
    static let f1Key: OSType = 0x6B737A00
    static let f2Key: OSType = 0x6B737800
    static let f3Key: OSType = 0x6B736300
    static let f4Key: OSType = 0x6B737600
    static let f5Key: OSType = 0x6B736000
    static let f6Key: OSType = 0x6B736100
    static let f7Key: OSType = 0x6B736200
    static let f8Key: OSType = 0x6B736400
    static let f9Key: OSType = 0x6B736500
    static let forwardDelKey: OSType = 0x6B737500
    static let helpKey: OSType = 0x6B737200
    static let homeKey: OSType = 0x6B737300
    static let keyKind: OSType = 0x656B7374
    static let leftArrowKey: OSType = 0x6B737B00
    static let modifiers: OSType = 0x654D6473
    static let optionDown: OSType = 0x4B6F7074
    static let pageDownKey: OSType = 0x6B737900
    static let pageUpKey: OSType = 0x6B737400
    static let pointingDevice: OSType = 0x65647064
    static let postScript: OSType = 0x65707073
    static let returnKey: OSType = 0x6B732400
    static let rightArrowKey: OSType = 0x6B737C00
    static let scheme: OSType = 0x65736368
    static let shiftDown: OSType = 0x4B736674
    static let tabKey: OSType = 0x6B733000
    static let tokenRing: OSType = 0x65746F6B
    static let upArrowKey: OSType = 0x6B737E00
    static let urlAFP: OSType = 0x61667020
    static let urlAT: OSType = 0x61742020
    static let urlEPPC: OSType = 0x65707063
    static let urlFTP: OSType = 0x66747020
    static let urlFile: OSType = 0x66696C65
    static let urlGopher: OSType = 0x67706872
    static let urlHTTP: OSType = 0x68747470
    static let urlHTTPS: OSType = 0x68747073
    static let urlIMAP: OSType = 0x696D6170
    static let urlLDAP: OSType = 0x756C6470
    static let urlLaunch: OSType = 0x6C61756E
    static let urlMail: OSType = 0x6D61696C
    static let urlMailbox: OSType = 0x6D626F78
    static let urlMessage: OSType = 0x6D657373
    static let urlMulti: OSType = 0x6D756C74
    static let urlNFS: OSType = 0x756E6673
    static let urlNNTP: OSType = 0x6E6E7470
    static let urlNews: OSType = 0x6E657773
    static let urlPOP: OSType = 0x75706F70
    static let urlRTSP: OSType = 0x72747370
    static let urlSNews: OSType = 0x736E7773
    static let urlTelnet: OSType = 0x746C6E74
    static let urlUnknown: OSType = 0x75726C3F
    
}

extension AE4.TestPredicateKeywords {
    
    static let comparisonOperator: OSType = 0x72656c6f
    static let firstObject: OSType = 0x6f626a31
    static let secondObject: OSType = 0x6f626a32
    
    static let logicalOperator: OSType = 0x6c6f6763
    static let logicalTerms: OSType = 0x7465726d
    static let object: OSType = 0x6B6F626A
    
}

extension AE4.ObjectSpecifierKeywords {
    
    static let desiredClass: OSType = 0x77616e74
    static let container: OSType = 0x66726f6d
    static let keyForm: OSType = 0x666f726d
    static let keyData: OSType = 0x73656c64
    
}

extension AE4.RangeSpecifierKeywords {
    
    static let start: OSType = 0x73746172
    static let stop: OSType = 0x73746f70
    
}

extension AE4.InsertionSpecifierKeywords {

    static let object: OSType = 0x6B6F626A
    static let position: OSType = 0x6B706F73
    
}

extension AE4.Considerations {

    static let `case`: OSType = 0x63617365
    static let diacritic: OSType = 0x64696163
    static let whiteSpace: OSType = 0x77686974
    static let hyphens: OSType = 0x68797068
    static let expansion: OSType = 0x65787061
    static let punctuation: OSType = 0x70756E63
    static let numericStrings: OSType = 0x6E756D65
    
}

extension AE4.AESymbols {
    
    static let about: OSType = 0x61626F75
    static let activate: OSType = 0x61637476
    static let aliasSelection: OSType = 0x73616C69
    static let all: OSType = 0x616C6C20
    static let allCaps: OSType = 0x616C6370
    static let any: OSType = 0x616E7920
    static let applicationClass: OSType = 0x6170706C
    static let applicationDied: OSType = 0x6F626974
    static let ask: OSType = 0x61736B20
    static let autoDown: OSType = 0x6175746F
    static let beginsWith: OSType = 0x62677774
    static let bold: OSType = 0x626F6C64
    static let caseSensEquals: OSType = 0x63736571
    static let centered: OSType = 0x63656E74
    static let changeView: OSType = 0x76696577
    static let clone: OSType = 0x636C6F6E
    static let close: OSType = 0x636C6F73
    static let commandClass: OSType = 0x636D6E64
    static let condensed: OSType = 0x636F6E64
    static let contains: OSType = 0x636F6E74
    static let copy: OSType = 0x636F7079
    static let countElements: OSType = 0x636E7465
    static let createElement: OSType = 0x6372656C
    static let cut: OSType = 0x63757420
    static let deactivate: OSType = 0x64616374
    static let delete: OSType = 0x64656C6F
    static let diskEvent: OSType = 0x6469736B
    static let doObjectsExist: OSType = 0x646F6578
    static let doScript: OSType = 0x646F7363
    static let down: OSType = 0x646F776E
    static let drag: OSType = 0x64726167
    static let duplicateSelection: OSType = 0x73647570
    static let emptyTrash: OSType = 0x656D7074
    static let endsWith: OSType = 0x656E6473
    static let equals: OSType = 0x3D202020
    static let expanded: OSType = 0x70657870
    static let `false`: OSType = 0x66616C73
    static let fast: OSType = 0x66617374
    static let first: OSType = 0x66697273
    static let getClassInfo: OSType = 0x716F626A
    static let getData: OSType = 0x67657464
    static let getDataSize: OSType = 0x6473697A
    static let getEventInfo: OSType = 0x67746569
    static let getInfoSelection: OSType = 0x73696E66
    static let getPrivilegeSelection: OSType = 0x73707276
    static let greaterThan: OSType = 0x3E202020
    static let greaterThanEquals: OSType = 0x3E3D2020
    static let grow: OSType = 0x67726F77
    static let hidden: OSType = 0x6869646E
    static let highLevel: OSType = 0x68696768
    static let isUniform: OSType = 0x6973756E
    static let keyClass: OSType = 0x6B657963
    static let keyDown: OSType = 0x6B64776E
    static let last: OSType = 0x6C617374
    static let logOut: OSType = 0x6C6F676F
    static let lowercase: OSType = 0x6C6F7763
    static let makeObjectsVisible: OSType = 0x6D766973
    static let middle: OSType = 0x6D696464
    static let modifiable: OSType = 0x6D6F6466
    static let mouseClass: OSType = 0x6D6F7573
    static let mouseDown: OSType = 0x6D64776E
    static let mouseDownInBack: OSType = 0x6D64626B
    static let move: OSType = 0x6D6F7665
    static let moved: OSType = 0x6D6F7665
    static let navigationKey: OSType = 0x6E617665
    static let next: OSType = 0x6E657874
    static let no: OSType = 0x6E6F2020
    static let noArrow: OSType = 0x61726E6F
    static let nonmodifiable: OSType = 0x6E6D6F64
    static let notifyRecording: OSType = 0x72656372
    static let notifyStartRecording: OSType = 0x72656331
    static let notifyStopRecording: OSType = 0x72656330
    static let nullEvent: OSType = 0x6E756C6C
    static let `open`: OSType = 0x6F646F63
    static let openContents: OSType = 0x6F636F6E
    static let openDocuments: OSType = 0x6F646F63
    static let openSelection: OSType = 0x736F7065
    static let outline: OSType = 0x6F75746C
    static let pageSetup: OSType = 0x70677375
    static let paste: OSType = 0x70617374
    static let plain: OSType = 0x706C616E
    static let previous: OSType = 0x70726576
    static let print: OSType = 0x70646F63
    static let printDocuments: OSType = 0x70646F63
    static let printSelection: OSType = 0x73707269
    static let printWindow: OSType = 0x7077696E
    static let promise: OSType = 0x70726F6D
    static let quitAll: OSType = 0x71756961
    static let quitApplication: OSType = 0x71756974
    static let rawKey: OSType = 0x726B6579
    static let reallyLogOut: OSType = 0x726C676F
    static let redo: OSType = 0x7265646F
    static let regular: OSType = 0x7265676C
    static let reopenApplication: OSType = 0x72617070
    static let replace: OSType = 0x72706C63
    static let resized: OSType = 0x7273697A
    static let restart: OSType = 0x72657374
    static let resume: OSType = 0x72736D65
    static let revealSelection: OSType = 0x73726576
    static let revert: OSType = 0x72767274
    static let save: OSType = 0x73617665
    static let scrapEvent: OSType = 0x73637270
    static let scriptingSizeResource: OSType = 0x7363737A
    static let select: OSType = 0x736C6374
    static let setData: OSType = 0x73657464
    static let setPosition: OSType = 0x706F736E
    static let shadow: OSType = 0x73686164
    static let sharedScriptHandler: OSType = 0x77736370
    static let showClipboard: OSType = 0x7368636C
    static let showPreferences: OSType = 0x70726566
    static let showRestartDialog: OSType = 0x72727374
    static let showShutdownDialog: OSType = 0x7273646E
    static let shutDown: OSType = 0x73687574
    static let sleep: OSType = 0x736C6570
    static let specialClassProperties: OSType = 0x63402321
    static let startRecording: OSType = 0x72656361
    static let stopRecording: OSType = 0x72656363
    static let stoppedMoving: OSType = 0x73746F70
    static let `subscript`: OSType = 0x73627363
    static let suspend: OSType = 0x73757370
    static let terminologyExtension: OSType = 0x61657465
    static let `true`: OSType = 0x74727565
    static let underline: OSType = 0x756E646C
    static let undo: OSType = 0x756E646F
    static let up: OSType = 0x75702020
    static let update: OSType = 0x75706474
    static let userTerminology: OSType = 0x61657574
    static let virtualKey: OSType = 0x6B657963
    static let wakeUpEvent: OSType = 0x77616B65
    static let wholeWordEquals: OSType = 0x77776571
    static let windowClass: OSType = 0x77696E64
    static let yes: OSType = 0x79657320
    static let zoom: OSType = 0x7A6F6F6D
    
}

extension AE4.ASSymbols {
    
    static let add: OSType = 0x2B202020
    static let comesAfter: OSType = 0x63616672
    static let comesBefore: OSType = 0x63626672
    static let comment: OSType = 0x636D6E74
    static let commentEvent: OSType = 0x636D6E74
    static let concatenate: OSType = 0x63636174
    static let considerReplies: OSType = 0x726D7465
    static let contains: OSType = 0x636F6E74
    static let currentApplication: OSType = 0x63757261
    static let divide: OSType = 0x2F202020
    static let endsWith: OSType = 0x656E6473
    static let equal: OSType = 0x3D202020
    static let errorEventCode: OSType = 0x65727220
    static let greaterThan: OSType = 0x3E202020
    static let greaterThanOrEqual: OSType = 0x3E3D2020
    static let hasOpenHandler: OSType = 0x68736F64
    static let initializeEventCode: OSType = 0x696E6974
    static let magicEndTellEvent: OSType = 0x74656E64
    static let magicTellEvent: OSType = 0x74656C6C
    static let multiply: OSType = 0x2A202020
    static let negate: OSType = 0x6E656720
    static let prepositionalSubroutine: OSType = 0x70736272
    static let quotient: OSType = 0x64697620
    static let remainder: OSType = 0x6D6F6420
    static let startLogEvent: OSType = 0x6C6F6731
    static let startsWith: OSType = 0x62677774
    static let stopLogEvent: OSType = 0x6C6F6730
    static let subroutineEvent: OSType = 0x70736272
    static let subtract: OSType = 0x2D202020
    
}

extension AE4.Suites {
    
    static let coreSuite: OSType = 0x636F7265
    static let getSuiteInfo: OSType = 0x67747369
    static let internetSuite: OSType = 0x6775726C
    static let requiredSuite: OSType = 0x72657164
    static let tableSuite: OSType = 0x74626C73
    static let textSuite: OSType = 0x54455854
    static let scriptEditorSuite: OSType = 0x546F7953
    static let asTypeNamesSuite: OSType = 0x74706E6D
    static let osaSuite: OSType = 0x61736372

}

extension AE4.ASOSASymbols {
    
    static let _kAppleScriptSubtype: OSType = 0x61736372
    
}

extension AE4.Keywords {
    
    static let directObject: OSType = 0x2D2D2D2D
    static let requestedType: OSType = 0x72747970
    
    static let errorNumber: OSType = 0x6572726E
    static let errorString: OSType = 0x65727273
    static let processSerialNumber: OSType = 0x70736E20
    
    /// "make" -> "at" parameter
    static let insertHere: OSType = 0x696E7368
    
}

extension AE4.Attributes {
    
    static let eventClass: OSType = 0x6576636C
    static let eventID: OSType = 0x65766964
    static let eventSource: OSType = 0x65737263
    static let interactLevel: OSType = 0x696E7465
    static let optionalKeyword: OSType = 0x6F70746B
    static let originalAddress: OSType = 0x66726F6D
    static let replyPort: OSType = 0x72657070
    static let replyRequested: OSType = 0x72657071
    static let returnID: OSType = 0x72746964
    static let subject: OSType = 0x7375626A
    static let timeout: OSType = 0x74696D6F
    static let transactionID: OSType = 0x7472616E
    static let considerations: OSType = 0x636F6E73
    static let considsAndIgnores: OSType = 0x63736967
    
}

extension AE4.Events {
    
    public enum Core {
        
        static let eventClass: OSType = 0x61657674
        
        public enum IDs {
            
            /// Event ID of reply events.
            static let answer: OSType = 0x616E7372
            
            static let openApplication: OSType = 0x6F617070
            
        }
        
    }
    
    public enum Transactions {
        
        static let eventClass: OSType = 0x6D697363
        
        public enum IDs {
            
            static let begin: OSType = 0x62656769
            static let end: OSType = 0x656E6474
            static let terminated: OSType = 0x7474726D
            
        }
        
    }
    
    public enum AppleScript {

        static let eventClass: OSType = 0x61736372
        
        public enum IDs {
            
            /// Call a user-defined AppleScript subroutine.
            static let callSubroutine: OSType = 0x70736272
            
            /// No-op.
            static let launch: OSType = 0x6E6F6F70
            
            /// Request app terminology in 'aete' resource format.
            /// (AETE means AppleEvent Trminology Extension.)
            static let getAETE: OSType = 0x67647465
            /// Request AppleScript built-in terminology in 'aete' resource format.
            /// (AEUT means AppleEvent User Terminology.)
            static let getAEUT: OSType = 0x67647574

            static let updateAETE: OSType = 0x75647465
            static let updateAEUT: OSType = 0x75647574
            
            /// Sent by OSA to current application with a chunk of recorded script text.
            static let recordedText: OSType = 0x72656364
            
        }
        
        public enum Keywords {
            
            /// Name of the user-defined subroutine for callSubroutine.
            static let subroutineName: OSType = 0x736E616D
            /// Positional subroutine arguments for callSubroutine.
            static let positionalArguments: OSType = 0x70617267
            
            // Keywords for predefined "prepositional" subroutine parameter names.
            public enum Prepositions {
                
                static let about: OSType = 0x61626F75
                static let above: OSType = 0x61627665
                static let against: OSType = 0x61677374
                static let apartFrom: OSType = 0x61707274
                static let around: OSType = 0x61726E64
                static let asideFrom: OSType = 0x61736466
                static let at: OSType = 0x61742020
                static let below: OSType = 0x62656C77
                static let beneath: OSType = 0x626E7468
                static let beside: OSType = 0x62736964
                static let between: OSType = 0x6274776E
                static let by: OSType = 0x62792020
                static let `for`: OSType = 0x666F7220
                static let from: OSType = 0x66726F6D
                static let given: OSType = 0x6769766E
                static let `in`: OSType = 0x696E2020
                static let insteadOf: OSType = 0x6973746F
                static let into: OSType = 0x696E746F
                static let on: OSType = 0x6F6E2020
                static let onto: OSType = 0x6F6E746F
                static let outOf: OSType = 0x6F75746F
                static let over: OSType = 0x6F766572
                static let since: OSType = 0x736E6365
                static let through: OSType = 0x74686768
                static let thru: OSType = 0x74687275
                static let to: OSType = 0x746F2020
                static let under: OSType = 0x756E6472
                static let until: OSType = 0x74696C6C
                static let with: OSType = 0x77697468
                static let without: OSType = 0x776F7574  
                
            }
            
        }
        
    }
    
    public enum DigitalHub {

        static let eventClass: OSType = 0x64687562
        
        public enum IDs {
            
            static let blankCD: OSType = 0x62636420
            static let blankDVD: OSType = 0x62647664
            static let musicCD: OSType = 0x61756364
            static let pictureCD: OSType = 0x70696364
            static let videoDVD: OSType = 0x76647664
            
        }
        
    }
    
    public enum FolderActions {
        
        public enum IDs {
            
            static let opened: OSType = 0x666F706E
            static let closed: OSType = 0x66636C6F
            static let itemsAdded: OSType = 0x66676574
            static let itemsRemoved: OSType = 0x666C6F73
            static let windowMoved: OSType = 0x6673697A
            
        }
        
        public enum Keywords {
            
            /// Size of moved window.
            static let newSize: OSType = 0x666E737A
            
        }
        
    }
    
}

extension AE4.OSAErrorKeywords {
    
    static let app: OSType = 0x65726170
    static let args: OSType = 0x65727261
    static let briefMessage: OSType = 0x65727262
    static let expectedType: OSType = 0x65727274
    static let message: OSType = 0x65727273
    static let number: OSType = 0x6572726E
    static let offendingObject: OSType = 0x65726F62
    static let partialResult: OSType = 0x70746C72
    static let range: OSType = 0x65726E67
    
}

extension AE4.OSASymbols {
    
    static let genericScriptingComponentSubtype: OSType = 0x73637074
    static let scriptBestType: OSType = 0x62657374
    static let scriptIsModified: OSType = 0x6D6F6469
    static let scriptIsTypeCompiledScript: OSType = 0x63736372
    static let scriptIsTypeScriptContext: OSType = 0x636E7478
    static let scriptIsTypeScriptValue: OSType = 0x76616C75

    static let dialectCode: OSType = 0x64636F64
    static let dialectLangCode: OSType = 0x646C6364
    static let dialectName: OSType = 0x646E616D
    static let dialectScriptCode: OSType = 0x64736364
    static let sourceEnd: OSType = 0x73726365
    static let sourceStart: OSType = 0x73726373
    
}

extension AE4.ASKeywords {

    static let userRecordFields: OSType = 0x75737266
    
}

extension AE4.Properties {
    
    static let bestType: OSType = 0x70627374
    static let bounds: OSType = 0x70626E64
    static let `class`: OSType = 0x70636C73
    static let clipboard: OSType = 0x70636C69
    static let color: OSType = 0x636F6C72
    static let contents: OSType = 0x70636E74
    static let defaultType: OSType = 0x64656674
    static let enabled: OSType = 0x656E626C
    static let endPoint: OSType = 0x70656E64
    static let font: OSType = 0x666F6E74
    static let hasCloseBox: OSType = 0x68636C62
    static let hasTitleBar: OSType = 0x70746974
    static let id: OSType = 0x49442020
    static let index: OSType = 0x70696478
    static let inherits: OSType = 0x6340235E
    static let insertionLoc: OSType = 0x70696E73
    static let isFloating: OSType = 0x6973666C
    static let isFrontProcess: OSType = 0x70697366
    static let isModal: OSType = 0x706D6F64
    static let isModified: OSType = 0x696D6F64
    static let isResizable: OSType = 0x7072737A
    static let isStationeryPad: OSType = 0x70737064
    static let isZoomable: OSType = 0x69737A6D
    static let isZoomed: OSType = 0x707A756D
    static let itemNumber: OSType = 0x69746D6E
    static let keyKind: OSType = 0x6B6B6E64
    static let keystrokeKey: OSType = 0x6B4D7367
    static let langCode: OSType = 0x706C6364
    static let length: OSType = 0x6C656E67
    static let name: OSType = 0x706E616D
    static let newElementLoc: OSType = 0x706E656C
    static let path: OSType = 0x46545063
    static let properties: OSType = 0x70414C4C
    static let protection: OSType = 0x7070726F
    static let rest: OSType = 0x72657374
    static let reverse: OSType = 0x72767365
    static let script: OSType = 0x73637074
    static let scriptCode: OSType = 0x70736364
    static let scriptTag: OSType = 0x70736374
    static let selected: OSType = 0x73656C63
    static let selection: OSType = 0x73656C65
    static let textItemDelimiters: OSType = 0x7478646C
    static let url: OSType = 0x7055524C
    static let version: OSType = 0x76657273
    static let visible: OSType = 0x70766973
    
}

extension AE4.ASProperties {
    
    static let dateString: OSType = 0x64737472
    static let day: OSType = 0x64617920
    static let days: OSType = 0x64617973
    static let hours: OSType = 0x686F7572
    static let it: OSType = 0x69742020
    static let me: OSType = 0x6D652020
    static let minutes: OSType = 0x6D696E20
    static let month: OSType = 0x6D6E7468
    static let parent: OSType = 0x70617265
    static let pi: OSType = 0x70692020
    static let printDepth: OSType = 0x70726470
    static let printLength: OSType = 0x70726C6E
    static let quote: OSType = 0x71756F74
    static let result: OSType = 0x72736C74
    static let `return`: OSType = 0x72657420
    static let seconds: OSType = 0x73656373
    static let space: OSType = 0x73706163
    static let tab: OSType = 0x74616220
    static let time: OSType = 0x74696D65
    static let timeString: OSType = 0x74737472
    static let topLevelScript: OSType = 0x61736372
    static let weekday: OSType = 0x776B6479
    static let weeks: OSType = 0x7765656B
    static let year: OSType = 0x79656172
    
}
    
extension AE4.Types {

    static let _128BitFloatingPoint: OSType = 0x6C64626C
    static let list: OSType = 0x6C697374
    static let record: OSType = 0x7265636F
    static let aete: OSType = 0x61657465
    static let aeText: OSType = 0x74545854
    static let aeut: OSType = 0x61657574
    static let asStorage: OSType = 0x61736372
    static let absoluteOrdinal: OSType = 0x6162736F
    static let alias: OSType = 0x616C6973
    static let appParameters: OSType = 0x61707061
    static let applSignature: OSType = 0x7369676E
    static let appleEvent: OSType = 0x61657674
    static let appleScript: OSType = 0x61736372
    static let applicationBundleID: OSType = 0x62756E64
    static let applicationURL: OSType = 0x6170726C
    static let arc: OSType = 0x63617263
    static let best: OSType = 0x62657374
    static let bookmarkData: OSType = 0x626D726B
    static let boolean: OSType = 0x626F6F6C
    static let cfAbsoluteTime: OSType = 0x63666174
    static let cfArrayRef: OSType = 0x63666172
    static let cfAttributedStringRef: OSType = 0x63666173
    static let cfBooleanRef: OSType = 0x63667466
    static let cfDictionaryRef: OSType = 0x63666463
    static let cfMutableArrayRef: OSType = 0x63666D61
    static let cfMutableAttributedStringRef: OSType = 0x63666161
    static let cfMutableDictionaryRef: OSType = 0x63666D64
    static let cfMutableStringRef: OSType = 0x63666D73
    static let cfNumberRef: OSType = 0x63666E62
    static let cfStringRef: OSType = 0x63667374
    static let cfTypeRef: OSType = 0x63667479
    static let cString: OSType = 0x63737472
    static let cell: OSType = 0x6363656C
    static let centimeters: OSType = 0x636D7472
    static let classInfo: OSType = 0x67636C69
    static let colorTable: OSType = 0x636C7274
    static let column: OSType = 0x63636F6C
    static let comp: OSType = 0x636F6D70
    static let compDescriptor: OSType = 0x636D7064
    static let componentInstance: OSType = 0x636D7069
    static let cubicCentimeter: OSType = 0x63636D74
    static let cubicFeet: OSType = 0x63666574
    static let cubicInches: OSType = 0x6375696E
    static let cubicMeters: OSType = 0x636D6574
    static let cubicYards: OSType = 0x63797264
    static let currentContainer: OSType = 0x63636E74
    static let dashStyle: OSType = 0x74646173
    static let data: OSType = 0x74647461
    static let decimalStruct: OSType = 0x6465636D
    static let degreesC: OSType = 0x64656763
    static let degreesF: OSType = 0x64656766
    static let degreesK: OSType = 0x6465676B
    static let elemInfo: OSType = 0x656C696E
    static let enumerated: OSType = 0x656E756D
    static let enumeration: OSType = 0x656E756D
    static let eventInfo: OSType = 0x6576696E
    static let eventRecord: OSType = 0x65767263
    static let eventRef: OSType = 0x65767266
    static let extended: OSType = 0x65787465
    static let fsRef: OSType = 0x66737266
    static let fss: OSType = 0x66737320
    static let `false`: OSType = 0x66616C73
    static let feet: OSType = 0x66656574
    static let fileURL: OSType = 0x6675726C
    static let finderWindow: OSType = 0x6677696E
    static let fixed: OSType = 0x66697864
    static let fixedPoint: OSType = 0x66706E74
    static let fixedRectangle: OSType = 0x66726374
    static let float: OSType = 0x646F7562
    static let gif: OSType = 0x47494666
    static let gallons: OSType = 0x67616C6E
    static let grams: OSType = 0x6772616D
    static let ieee32BitFloatingPoint: OSType = 0x73696E67
    static let ieee64BitFloatingPoint: OSType = 0x646F7562
    static let iso8601DateTime: OSType = 0x69736F74
    static let inches: OSType = 0x696E6368
    static let indexDescriptor: OSType = 0x696E6465
    static let insertionLoc: OSType = 0x696E736C
    static let integer: OSType = 0x6C6F6E67
    static let intlText: OSType = 0x69747874
    static let intlWritingCode: OSType = 0x696E746C
    static let jpeg: OSType = 0x4A504547
    static let kernelProcessID: OSType = 0x6B706964
    static let keyword: OSType = 0x6B657977
    static let kilograms: OSType = 0x6B67726D
    static let kilometers: OSType = 0x6B6D7472
    static let liters: OSType = 0x6C697472
    static let logicalDescriptor: OSType = 0x6C6F6769
    static let longDateTime: OSType = 0x6C647420
    static let longFixed: OSType = 0x6C667864
    static let longFixedPoint: OSType = 0x6C667074
    static let longFixedRectangle: OSType = 0x6C667263
    static let longFloat: OSType = 0x646F7562
    static let longInteger: OSType = 0x6C6F6E67
    static let longPoint: OSType = 0x6C706E74
    static let longRectangle: OSType = 0x6C726374
    static let machPort: OSType = 0x706F7274
    static let machineLoc: OSType = 0x6D4C6F63
    static let magnitude: OSType = 0x6D61676E
    static let meters: OSType = 0x6D657472
    static let miles: OSType = 0x6D696C65
    static let null: OSType = 0x6E756C6C
    static let osaDialectInfo: OSType = 0x6469666F
    static let osaErrorRange: OSType = 0x65726E67
    static let osaGenericStorage: OSType = 0x73637074
    static let objectBeingExamined: OSType = 0x65786D6E
    static let objectSpecifier: OSType = 0x6F626A20
    static let offsetArray: OSType = 0x6F666179
    static let ounces: OSType = 0x6F7A7320
    static let oval: OSType = 0x636F766C
    static let pString: OSType = 0x70737472
    static let paramInfo: OSType = 0x706D696E
    static let pict: OSType = 0x50494354
    static let pounds: OSType = 0x6C627320
    static let processSerialNumber: OSType = 0x70736E20
    static let propInfo: OSType = 0x70696E66
    static let property: OSType = 0x70726F70
    static let ptr: OSType = 0x70747220
    static let quarts: OSType = 0x71727473
    static let rgb16: OSType = 0x74723136
    static let rgb96: OSType = 0x74723936
    static let qdPoint: OSType = 0x51447074
    static let qdRectangle: OSType = 0x71647274
    static let rgbColor: OSType = 0x63524742
    static let rangeDescriptor: OSType = 0x72616E67
    static let rectangle: OSType = 0x63726563
    static let relativeDescriptor: OSType = 0x72656C20
    static let replyPortAttr: OSType = 0x72657070
    static let rotation: OSType = 0x74726F74
    static let roundedRectangle: OSType = 0x63727263
    static let row: OSType = 0x63726F77
    static let sInt16: OSType = 0x73686F72
    static let sInt32: OSType = 0x6C6F6E67
    static let sInt64: OSType = 0x636F6D70
    static let smFloat: OSType = 0x73696E67
    static let smInt: OSType = 0x73686F72
    static let script: OSType = 0x73637074
    static let scszResource: OSType = 0x7363737A
    static let sectionH: OSType = 0x73656374
    static let shortFloat: OSType = 0x73696E67
    static let shortInteger: OSType = 0x73686F72
    static let sound: OSType = 0x736E6420
    static let squareFeet: OSType = 0x73716674
    static let squareKilometers: OSType = 0x73716B6D
    static let squareMeters: OSType = 0x7371726D
    static let squareMiles: OSType = 0x73716D69
    static let squareYards: OSType = 0x73717964
    static let styledText: OSType = 0x53545854
    static let styledUnicodeText: OSType = 0x73757478
    static let tiff: OSType = 0x54494646
    static let table: OSType = 0x6374626C
    static let text: OSType = 0x54455854
    static let textRange: OSType = 0x7478726E
    static let textRangeArray: OSType = 0x74726179
    static let textStyles: OSType = 0x74737479
    static let token: OSType = 0x746F6B65
    static let `true`: OSType = 0x74727565
    static let type: OSType = 0x74797065
    static let uInt16: OSType = 0x75736872
    static let uInt32: OSType = 0x6D61676E
    static let uInt64: OSType = 0x75636F6D
    static let utf16ExternalRepresentation: OSType = 0x75743136
    static let utf8Text: OSType = 0x75746638
    static let unicodeText: OSType = 0x75747874
    static let userRecordFields: OSType = 0x6C697374
    static let version: OSType = 0x76657273
    static let whoseDescriptor: OSType = 0x77686F73
    static let whoseRange: OSType = 0x77726E67
    static let wildCard: OSType = 0x2A2A2A2A
    static let yards: OSType = 0x79617264
    
}

/******************************************************************************/
// MARK: Pre-encoded symbols

extension AE4.Descriptors {
    
    public enum Types {
        
        static let property = NSAppleEventDescriptor(typeCode: AE4.Types.property)
        
    }
    
    public enum IndexForms {
        
        static let property           = NSAppleEventDescriptor(enumCode: AE4.IndexForm.propertyID.rawValue)
        static let userProperty       = NSAppleEventDescriptor(enumCode: AE4.IndexForm.userPropertyID.rawValue)
        static let absolutePosition   = NSAppleEventDescriptor(enumCode: AE4.IndexForm.absolutePosition.rawValue)
        static let name               = NSAppleEventDescriptor(enumCode: AE4.IndexForm.name.rawValue)
        static let uniqueID           = NSAppleEventDescriptor(enumCode: AE4.IndexForm.uniqueID.rawValue)
        static let relativePosition   = NSAppleEventDescriptor(enumCode: AE4.IndexForm.relativePosition.rawValue)
        static let range              = NSAppleEventDescriptor(enumCode: AE4.IndexForm.range.rawValue)
        static let test               = NSAppleEventDescriptor(enumCode: AE4.IndexForm.test.rawValue)
        
    }
    
    public enum InsertionLocations {
        
        static let beginning           = NSAppleEventDescriptor(enumCode: AE4.InsertionLocation.beginning.rawValue)
        static let end                 = NSAppleEventDescriptor(enumCode: AE4.InsertionLocation.end.rawValue)
        static let before              = NSAppleEventDescriptor(enumCode: AE4.InsertionLocation.before.rawValue)
        static let after               = NSAppleEventDescriptor(enumCode: AE4.InsertionLocation.after.rawValue)
        
    }
    
    public enum AbsolutePositions {
        
        static let first               = NSAppleEventDescriptor(type: AE4.Types.absoluteOrdinal, code: AE4.AbsoluteOrdinal.first.rawValue)
        static let middle              = NSAppleEventDescriptor(type: AE4.Types.absoluteOrdinal, code: AE4.AbsoluteOrdinal.middle.rawValue)
        static let last                = NSAppleEventDescriptor(type: AE4.Types.absoluteOrdinal, code: AE4.AbsoluteOrdinal.last.rawValue)
        static let any                 = NSAppleEventDescriptor(type: AE4.Types.absoluteOrdinal, code: AE4.AbsoluteOrdinal.random.rawValue)
        static let all                 = NSAppleEventDescriptor(type: AE4.Types.absoluteOrdinal, code: AE4.AbsoluteOrdinal.all.rawValue)
        
    }
    
    public enum RelativePositions {
        
        static let previous            = NSAppleEventDescriptor(enumCode: AE4.RelativeOrdinal.previous.rawValue)
        static let next                = NSAppleEventDescriptor(enumCode: AE4.RelativeOrdinal.next.rawValue)
        
    }
    
    public enum ComparisonTests {
        
        static let lessThan            = NSAppleEventDescriptor(enumCode: AE4.Comparison.lessThan.rawValue)
        static let lessThanEquals      = NSAppleEventDescriptor(enumCode: AE4.Comparison.lessThanEquals.rawValue)
        static let equals              = NSAppleEventDescriptor(enumCode: AE4.Comparison.equals.rawValue)
        // Encoded as !(op1 == op2)
        static let notEquals           = NSAppleEventDescriptor(enumCode: AE4.notEquals)
        static let greaterThan         = NSAppleEventDescriptor(enumCode: AE4.Comparison.greaterThan.rawValue)
        static let greaterThanEquals   = NSAppleEventDescriptor(enumCode: AE4.Comparison.greaterThanEquals.rawValue)
        
    }
    
    public enum ContainmentTests {
        
        static let beginsWith          = NSAppleEventDescriptor(enumCode: AE4.Containment.beginsWith.rawValue)
        static let endsWith            = NSAppleEventDescriptor(enumCode: AE4.Containment.endsWith.rawValue)
        static let contains            = NSAppleEventDescriptor(enumCode: AE4.Containment.contains.rawValue)
        // Encoded as op2.contains(op1)
        static let isIn                = NSAppleEventDescriptor(enumCode: AE4.isIn)
        
    }
    
    public enum LogicalTests {
        
        // logic tests
        static let and                 = NSAppleEventDescriptor(enumCode: AE4.LogicalOperator.and.rawValue)
        static let or                  = NSAppleEventDescriptor(enumCode: AE4.LogicalOperator.or.rawValue)
        static let not                 = NSAppleEventDescriptor(enumCode: AE4.LogicalOperator.not.rawValue)
        
    }
    
}
