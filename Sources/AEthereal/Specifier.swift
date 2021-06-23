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

    // 'insl'
    public let insertionLocation: NSAppleEventDescriptor

    private(set) public var parentQuery: Query

    public init(insertionLocation: NSAppleEventDescriptor,
                         parentQuery: Query, app: App) {
        self.insertionLocation = insertionLocation
        self.parentQuery = parentQuery
        self.app = app
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        let desc = NSAppleEventDescriptor.record().coerce(toDescriptorType: typeInsertionLoc)!
        desc.setDescriptor(try parentQuery.encodeAEDescriptor(app), forKeyword: keyAEObject)
        desc.setDescriptor(insertionLocation, forKeyword: keyAEPosition)
        return desc
    }
    
    public enum Kind: OSType {
        case beginning = 0x62676E67, end = 0x656E6420
        case before = 0x6265666F, after = 0x61667465
    }
    
    public var kind: Kind? {
        return Kind(rawValue: insertionLocation.enumCodeValue)
    }
    
}

/// An object specifier.
public protocol ObjectSpecifier: Specifier {
    
    var wantType: NSAppleEventDescriptor { get }
    var selectorForm: NSAppleEventDescriptor { get }
    var selectorData: Any { get }
    
}

/// A property or single-element object specifier.
public class SingleObjectSpecifier: Specifier, ObjectSpecifier {
    
    public var app: App
    
    // 'want', 'form', 'seld'
    public let wantType: NSAppleEventDescriptor
    public let selectorForm: NSAppleEventDescriptor
    public let selectorData: Any
    
    private(set) public var parentQuery: Query

    public required init(wantType: NSAppleEventDescriptor, selectorForm: NSAppleEventDescriptor, selectorData: Any, parentQuery: Query, app: App) {
        self.wantType = wantType
        self.selectorForm = selectorForm
        self.selectorData = selectorData
        self.parentQuery = parentQuery
        self.app = app
    }

    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        let desc = NSAppleEventDescriptor.record().coerce(toDescriptorType: AE4.Types.objectSpecifier)!
        desc.setDescriptor(try parentQuery.encodeAEDescriptor(app), forKeyword: AE4.ObjectSpecifierKeywords.container)
        desc.setDescriptor(wantType, forKeyword: AE4.ObjectSpecifierKeywords.desiredClass)
        desc.setDescriptor(selectorForm, forKeyword: AE4.ObjectSpecifierKeywords.keyForm)
        desc.setDescriptor(try app.encode(selectorData), forKeyword: AE4.ObjectSpecifierKeywords.keyData)
        return desc
    }

    public func beginsWith(_ value: Any) -> TestClause {
        return ComparisonTest(operatorType: AE4.Descriptors.ContainmentTests.beginsWith, operand1: self, operand2: value, app: app)
    }

    public func endsWith(_ value: Any) -> TestClause {
        return ComparisonTest(operatorType: AE4.Descriptors.ContainmentTests.endsWith, operand1: self, operand2: value, app: app)
    }

    public func contains(_ value: Any) -> TestClause {
        return ComparisonTest(operatorType: AE4.Descriptors.ContainmentTests.contains, operand1: self, operand2: value, app: app)
    }

    public func isIn(_ value: Any) -> TestClause {
        return ComparisonTest(operatorType: AE4.Descriptors.ContainmentTests.isIn, operand1: self, operand2: value, app: app)
    }
    
}

public func <(lhs: SingleObjectSpecifier, rhs: Any) -> TestClause {
    return ComparisonTest(operatorType: AE4.Descriptors.ComparisonTests.lessThan, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func <=(lhs: SingleObjectSpecifier, rhs: Any) -> TestClause {
    return ComparisonTest(operatorType: AE4.Descriptors.ComparisonTests.lessThanEquals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func ==(lhs: SingleObjectSpecifier, rhs: Any) -> TestClause {
    return ComparisonTest(operatorType: AE4.Descriptors.ComparisonTests.equals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func !=(lhs: SingleObjectSpecifier, rhs: Any) -> TestClause {
    return ComparisonTest(operatorType: AE4.Descriptors.ComparisonTests.notEquals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func >(lhs: SingleObjectSpecifier, rhs: Any) -> TestClause {
    return ComparisonTest(operatorType: AE4.Descriptors.ComparisonTests.greaterThan, operand1: lhs, operand2: rhs, app: lhs.app)
}

public func >=(lhs: SingleObjectSpecifier, rhs: Any) -> TestClause {
    return ComparisonTest(operatorType: AE4.Descriptors.ComparisonTests.greaterThanEquals, operand1: lhs, operand2: rhs, app: lhs.app)
}

public struct RangeSelector: AEEncodable { // holds data for by-range selectors
    // Start and stop are Con-based (i.e. relative to container) specifiers (App-based specifiers will also work, as
    // long as they have the same parent specifier as the by-range specifier itself). For convenience, users can also
    // pass non-specifier values (typically Strings and Ints) to represent simple by-name and by-index specifiers of
    // the same element class; these will be converted to specifiers automatically when encoded.
    public let start: Any
    public let stop: Any
    public let wantType: NSAppleEventDescriptor

    public init(start: Any, stop: Any, wantType: NSAppleEventDescriptor) {
        self.start = start
        self.stop = stop
        self.wantType = wantType
    }

    private func encode(_ selectorData: Any, app: App) throws -> NSAppleEventDescriptor {
        var selectorForm: NSAppleEventDescriptor
        switch selectorData {
        case is NSAppleEventDescriptor:
            return selectorData as! NSAppleEventDescriptor
        case is Specifier: // technically, only SingleObjectSpecifier makes sense here, tho AS prob. doesn't prevent insertion loc or multi-element specifier being passed instead
            return try (selectorData as! Specifier).encodeAEDescriptor(app)
        default: // encode anything else as a by-name or by-index specifier
            selectorForm = selectorData is String ? AE4.Descriptors.IndexForms.name : AE4.Descriptors.IndexForms.absolutePosition
            let desc = NSAppleEventDescriptor.record().coerce(toDescriptorType: AE4.Types.objectSpecifier)!
            desc.setDescriptor(containerRoot, forKeyword: AE4.ObjectSpecifierKeywords.container)
            desc.setDescriptor(wantType, forKeyword: AE4.ObjectSpecifierKeywords.desiredClass)
            desc.setDescriptor(selectorForm, forKeyword: AE4.ObjectSpecifierKeywords.keyForm)
            desc.setDescriptor(try app.encode(selectorData), forKeyword: AE4.ObjectSpecifierKeywords.keyData)
            return desc
        }
    }

    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        let desc = NSAppleEventDescriptor.record().coerce(toDescriptorType: AE4.Types.rangeDescriptor)!
        desc.setDescriptor(try encode(start, app: app), forKeyword: AE4.RangeSpecifierKeywords.start)
        desc.setDescriptor(try encode(stop, app: app), forKeyword: AE4.RangeSpecifierKeywords.stop)
        return desc
    }
}

/// A test clause. Must descend from a `RootSpecifier` with kind `.specimen`.
public protocol TestClause: Query {
}

public func &&(lhs: TestClause, rhs: TestClause) -> TestClause {
    return LogicalTest(operatorType: AE4.Descriptors.LogicalTests.and, operands: [lhs, rhs], app: lhs.app)
}

public func ||(lhs: TestClause, rhs: TestClause) -> TestClause {
    return LogicalTest(operatorType: AE4.Descriptors.LogicalTests.or, operands: [lhs, rhs], app: lhs.app)
}

public prefix func !(op: TestClause) -> TestClause {
    return LogicalTest(operatorType: AE4.Descriptors.LogicalTests.not, operands: [op], app: op.app)
}

/// A comparison or containment test clause.
public class ComparisonTest: TestClause {
    
    public var app: App
    
    public let operatorType: NSAppleEventDescriptor, operand1: SingleObjectSpecifier, operand2: Any
    
    init(operatorType: NSAppleEventDescriptor,
         operand1: SingleObjectSpecifier, operand2: Any, app: App) {
        self.operatorType = operatorType
        self.operand1 = operand1
        self.operand2 = operand2
        self.app = app
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        if operatorType === AE4.Descriptors.ComparisonTests.notEquals { // AEM doesn't support a 'kAENotEqual' enum...
            return try (!(operand1 == operand2)).encodeAEDescriptor(app) // so convert to kAEEquals+kAENOT
        } else {
            let desc = NSAppleEventDescriptor.record().coerce(toDescriptorType: AE4.Types.compDescriptor)!
            let opDesc1 = try app.encode(operand1)
            let opDesc2 = try app.encode(operand2)
            if operatorType === AE4.Descriptors.ContainmentTests.isIn { // AEM doesn't support a 'kAEIsIn' enum...
                desc.setDescriptor(AE4.Descriptors.ContainmentTests.contains, forKeyword: AE4.TestPredicateKeywords.comparisonOperator) // so use kAEContains with operands reversed
                desc.setDescriptor(opDesc2, forKeyword: AE4.TestPredicateKeywords.firstObject)
                desc.setDescriptor(opDesc1, forKeyword: AE4.TestPredicateKeywords.secondObject)
            } else {
                desc.setDescriptor(operatorType, forKeyword: AE4.TestPredicateKeywords.comparisonOperator)
                desc.setDescriptor(opDesc1, forKeyword: AE4.TestPredicateKeywords.firstObject)
                desc.setDescriptor(opDesc2, forKeyword: AE4.TestPredicateKeywords.secondObject)
            }
            return desc
        }
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

    public let operatorType: NSAppleEventDescriptor
    public let operands: [TestClause] // note: this doesn't have a 'parent' as such; to walk chain, just use first operand

    init(operatorType: NSAppleEventDescriptor, operands: [TestClause], app: App) {
        self.operatorType = operatorType
        self.operands = operands
        self.app = app
    }
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        let desc = NSAppleEventDescriptor.record().coerce(toDescriptorType: typeLogicalDescriptor)!
        desc.setDescriptor(operatorType, forKeyword: AE4.TestPredicateKeywords.logicalOperator)
        desc.setDescriptor(try app.encode(operands), forKeyword: AE4.TestPredicateKeywords.logicalTerms)
        return desc
    }
    
    public var parentQuery: Query {
        return operands[0]
    }

    public var rootSpecifier: RootSpecifier {
        return operands[0].rootSpecifier
    }
    
}

/// The root of all specifier chains.
public class RootSpecifier: ObjectSpecifier {
    
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
        case object(NSAppleEventDescriptor)
    }
    
    public var kind: Kind
    
    public init(_ kind: Kind, app: App) {
        self.kind = kind
        self.app = app
    }
    
    public var wantType: NSAppleEventDescriptor {
        .null()
    }
    public var selectorForm: NSAppleEventDescriptor {
        .null()
    }
    
    public var selectorData: Any {
        switch kind {
        case .application:
            return applicationRoot
        case .container:
            return containerRoot
        case .specimen:
            return specimenRoot
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
    
    public func encodeAEDescriptor(_ app: App) throws -> NSAppleEventDescriptor {
        try app.encode(selectorData)
    }
    
}
