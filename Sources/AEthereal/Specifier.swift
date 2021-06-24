//  Originally written by hhas.
//  See README.md for licensing information.

//
//  Base classes for constructing AE queries.
//
//  Notes:
//
//  An AE query is represented as a linked list of AEDescs, primarily AERecordDescs of typeObjectSpecifier. Each object specifier record has four properties:
//
//      'want' -- the type of element to identify (or 'prop' when identifying a property)
//      'form', 'seld' -- the reference form and selector data identifying the element(s) or property
//      'from' -- the parent descriptor in the linked list
//
//    For example:
//
//      name of document "ReadMe" [of application "TextEdit"]
//
//    is represented by the following chain of AEDescs:
//
//      {want:'prop', form:'prop', seld:'pnam', from:{want:'docu', form:'name', seld:"ReadMe", from:null}}
//
//    Additional AERecord types (typeInsertionLocation, typeRangeDescriptor, typeCompDescriptor, typeLogicalDescriptor) are also used to construct specialized query forms describing insertion points before/after existing elements, element ranges, and test clauses.
//
//    Atomic AEDescs of typeNull, typeCurrentContainer, and typeObjectBeingExamined are used to terminate the linked list.
//
//
//  [TO DO: developer notes on Apple event query forms and Apple Event Object Model's relational object graphs (objects with attributes, one-to-one relationships, and one-to-many relationships); aka "AE IPC is simple first-class relational queries, not OOP"]
//
//
//  Specifier.swift defines the base classes from which concrete Specifier classes representing each major query form are constructed. These base classes combine with various SpecifierExtensions (which provide by-index, by-name, etc selectors and Application object constructors) and glue-defined Query and Command extensions (which provide property and all-elements selectors, and commands) to form the following concrete classes:
//
//    CLASS                 DESCRIPTION                         CAN CONSTRUCT
//
//    Query                 [base class]
//     ├─PREFIXInsertion    insertion location specifier        ├─commands
//     └─PREFIXObject       [object specifier base protocol]    └─commands, and property and all-elements specifiers
//        ├─PREFIXItem         single-object specifier             ├─previous/next selectors
//        │  └─PREFIXItems     multi-object specifier              │  └─by-index/name/id/ordinal/range/test selectors
//        └─PREFIXRoot         App/Con/Its (untargeted roots)      ├─[1]
//           └─APPLICATION     Application (app-targeted root)     └─initializers
//
//
//    (The above diagram fudges the exact inheritance hierarchy for illustrative purposes. Commands are actually provided by a PREFIXCommand protocol [not shown], which is adopted by APPLICATION and all PREFIX classes except PREFIXRoot [1] - which cannot construct working commands as it has no target information, so omits these methods for clarity. Strictly speaking, the only class which should implement commands is APPLICATION, as Apple event IPC is based on Remote *Procedure* Calls, not OOP; however, they also appear on specifier classes as a convenient shorthand when writing commands whose direct parameter is a specifier. Note that while all specifier classes provide command methods [including those used to construct relative-specifiers in by-range and by-test clauses, as omitting commands from these is more trouble than its worth] they will automatically throw if their root is an untargeted App/Con/Its object.)
//
//    The following classes are also defined for use with Its-based object specifiers in by-test selectors.
//
//    Query
//     └─TestClause         [test clause base class]
//        ├─ComparisonTest     comparison/containment test
//        └─LogicalTest        Boolean logic test
//
//
//    Except for APPLICATION, users do not instantiate any of these classes directly, but instead by chained property/method calls on existing Query instances.
//

import Foundation
import AppKit

/// An AppleEvent object model query component.
/// Should either be a specifier or a test clause.
public protocol Query: AEEncodable {
    
    var rootSpecifier: RootSpecifier { get }

    var app: App { get set }
    
}

/// A specifier, which is a chainable AppleEvent object model query.
public protocol Specifier: Query {
    
    var app: App { get set }
    
    var parentQuery: Query { get }
    var rootSpecifier: RootSpecifier { get }
    
}

extension Specifier {
    
    public var rootSpecifier: RootSpecifier {
        return parentQuery.rootSpecifier
    }
    
}

/// An insertion location specifier.
public final class InsertionSpecifier: Specifier {
    
    public var app: App

    public let insertionLocation: AE4.InsertionLocation

    private(set) public var parentQuery: Query

    public init(insertionLocation: AE4.InsertionLocation, parentQuery: Query, app: App) {
        self.insertionLocation = insertionLocation
        self.parentQuery = parentQuery
        self.app = app
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try .insertionSpecifier(container: parentQuery, location: insertionLocation, app: app)
    }
    
}

/// An object specifier.
public protocol ObjectSpecifier: Specifier {
    
    var wantType: AE4.AEType { get }
    var selectorForm: AE4.IndexForm { get }
    var selectorData: AEEncodable { get }
    
}

/// A property or single-element object specifier.
public class SingleObjectSpecifier: Specifier, ObjectSpecifier {
    
    public var app: App
    
    // 'want', 'form', 'seld'
    public let wantType: AE4.AEType
    public let selectorForm: AE4.IndexForm
    public let selectorData: AEEncodable
    
    private(set) public var parentQuery: Query

    public required init(wantType: AE4.AEType, selectorForm: AE4.IndexForm, selectorData: AEEncodable, parentQuery: Query, app: App) {
        self.wantType = wantType
        self.selectorForm = selectorForm
        self.selectorData = selectorData
        self.parentQuery = parentQuery
        self.app = app
    }

    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try .objectSpecifier(container: parentQuery, type: wantType, form: selectorForm, data: selectorData, app: app)
    }

    public func beginsWith(_ value: AEEncodable) -> TestClause {
        return ComparisonTest(operatorType: .beginsWith, operand1: self, operand2: value, app: app)
    }

    public func endsWith(_ value: AEEncodable) -> TestClause {
        return ComparisonTest(operatorType: .endsWith, operand1: self, operand2: value, app: app)
    }

    public func contains(_ value: AEEncodable) -> TestClause {
        return ComparisonTest(operatorType: .contains, operand1: self, operand2: value, app: app)
    }

    public func isIn(_ value: AEEncodable) -> TestClause {
        return ComparisonTest(operatorType: .isIn, operand1: self, operand2: value, app: app)
    }
    
}

public func <(lhs: SingleObjectSpecifier, rhs: AEEncodable) -> TestClause {
    return ComparisonTest(operatorType: .lessThan, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func <=(lhs: SingleObjectSpecifier, rhs: AEEncodable) -> TestClause {
    return ComparisonTest(operatorType: .lessThanEquals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func ==(lhs: SingleObjectSpecifier, rhs: AEEncodable) -> TestClause {
    return ComparisonTest(operatorType: .equals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func !=(lhs: SingleObjectSpecifier, rhs: AEEncodable) -> TestClause {
    return ComparisonTest(operatorType: .notEquals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func >(lhs: SingleObjectSpecifier, rhs: AEEncodable) -> TestClause {
    return ComparisonTest(operatorType: .greaterThan, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func >=(lhs: SingleObjectSpecifier, rhs: AEEncodable) -> TestClause {
    return ComparisonTest(operatorType: .greaterThanEquals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public struct RangeSelector: AEEncodable { // holds data for by-range selectors
    // Start and stop are Con-based (i.e. relative to container) specifiers (App-based specifiers will also work, as
    // long as they have the same parent specifier as the by-range specifier itself). For convenience, users can also
    // pass non-specifier values (typically Strings and Ints) to represent simple by-name and by-index specifiers of
    // the same element class; these will be converted to specifiers automatically when encoded.
    public let start: AEEncodable
    public let stop: AEEncodable
    public let wantType: AE4.AEType

    public init(start: AEEncodable, stop: AEEncodable, wantType: AE4.AEType) {
        self.start = start
        self.stop = stop
        self.wantType = wantType
    }

    private func encode(_ selectorData: AEEncodable, app: App) throws -> AEDescriptor {
        switch selectorData {
        case is AEDescriptor:
            return selectorData as! AEDescriptor
        case is Specifier: // technically, only SingleObjectSpecifier makes sense here, tho AS prob. doesn't prevent insertion loc or multi-element specifier being passed instead
            return try (selectorData as! Specifier).encodeAEDescriptor(app)
        default: // encode anything else as a by-name or by-index specifier
            let selectorForm: AE4.IndexForm = selectorData is String ? .name : .absolutePosition
            return try AEDescriptor.objectSpecifier(container: AEDescriptor.containerRoot, type: wantType, form: selectorForm, data: selectorData, app: app)
        }
    }

    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try .range(start: start, stop: stop, app: app)
    }
    
    public init(from descriptor: AEDescriptor, wantType: AE4.AEType, app: App) throws {
        guard descriptor.type == .rangeDescriptor else {
            throw DecodeError(descriptor: descriptor, type: RangeSelector.self, message: "Malformed selector in by-range specifier.")
        }
        guard
            let startDesc = descriptor[AE4.RangeSpecifierKeywords.start],
            let stopDesc = descriptor[AE4.RangeSpecifierKeywords.stop]
        else {
            throw DecodeError(descriptor: descriptor, type: RangeSelector.self, message: "Malformed selector in by-range specifier.")
        }
        do {
            self.init(start: try app.decode(startDesc), stop: try app.decode(stopDesc), wantType: wantType)
        } catch {
            throw DecodeError(descriptor: descriptor, type: RangeSelector.self, message: "Couldn't decode start/stop selector in by-range specifier.")
        }
    }
    
}

/// A test clause. Must descend from a `RootSpecifier` with kind `.specimen`.
public protocol TestClause: Query {
}

public func &&(lhs: TestClause, rhs: TestClause) -> TestClause {
    return LogicalTest(operatorType: .and, operands: [lhs, rhs], app: lhs.app)
}

public func ||(lhs: TestClause, rhs: TestClause) -> TestClause {
    return LogicalTest(operatorType: .or, operands: [lhs, rhs], app: lhs.app)
}

public prefix func !(op: TestClause) -> TestClause {
    return LogicalTest(operatorType: .not, operands: [op], app: op.app)
}

/// A comparison or containment test clause.
public class ComparisonTest: TestClause {
    
    public var app: App
    
    public let operatorType: AE4.Comparison, operand1: SingleObjectSpecifier, operand2: AEEncodable
    
    init(operatorType: AE4.Comparison, operand1: SingleObjectSpecifier, operand2: AEEncodable, app: App) {
        self.operatorType = operatorType
        self.operand1 = operand1
        self.operand2 = operand2
        self.app = app
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        if operatorType == .notEquals {
            return try (!(operand1 == operand2)).encodeAEDescriptor(app)
        }
        if operatorType == .isIn {
            return try .comparison(operator: .contains, lhs: operand2, rhs: operand1, app: app)
        }
        return try .comparison(operator: operatorType, lhs: operand1, rhs: operand2, app: app)
    }
    
    public var parentQuery: Query {
        return operand1
    }
    
    public var rootSpecifier: RootSpecifier {
        return operand1.rootSpecifier
    }
    
}

/// A boolean operation test clause.
public class LogicalTest: TestClause {
    
    public var app: App

    public let operatorType: AE4.LogicalOperator
    public let operands: [TestClause] // note: this doesn't have a 'parent' as such; to walk chain, just use first operand

    init(operatorType: AE4.LogicalOperator, operands: [TestClause], app: App) {
        self.operatorType = operatorType
        self.operands = operands
        self.app = app
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try .logical(operator: operatorType, operands: operands, app: app)
    }
    
    public var parentQuery: Query {
        operands[0]
    }
    public var rootSpecifier: RootSpecifier {
        operands[0].rootSpecifier
    }
    
}

/// The root of all specifier chains.
public final class RootSpecifier: Specifier {
    
    public var app: App
    
    public enum Kind {
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
    }
    
    public var kind: Kind
    
    public init(_ kind: Kind, app: App) {
        self.kind = kind
        self.app = app
    }
    
    public var selectorData: AEEncodable {
        switch kind {
        case .application:
            return AEDescriptor.appRoot
        case .container:
            return AEDescriptor.containerRoot
        case .specimen:
            return AEDescriptor.specimenRoot
        case let .object(descriptor):
            return descriptor
        }
    }
    
    public var parentQuery: Query {
        self
    }
    public var rootSpecifier: RootSpecifier {
        self
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> AEDescriptor {
        try app.encode(selectorData)
    }
    
    public convenience init(from descriptor: AEDescriptor, app: App) throws {
        switch descriptor.type {
        case .null:
            self.init(.application, app: app)
        case .currentContainer:
            self.init(.container, app: app)
        case .objectBeingExamined:
            self.init(.specimen, app: app)
        default:
            self.init(.object(descriptor), app: app)
        }
    }
    
}
