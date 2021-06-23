//  Originally written by hhas.
//  See README.md for licensing information.

//
//  Extensions that add the standard selector vars/methods to Specifier classes.
//  These allow specifiers to be built up via chained calls, e.g.:
//
//     paragraphs 1 thru -2 of text of document "README" of it
//
//     App.generic.application.elements(cDocument)["README"].property(cText).elements(cParagraph)[1,-2]
//

import Foundation

/******************************************************************************/
// Property/single-element specifier; identifies an attribute/describes a one-to-one relationship between nodes in the app's AEOM graph

public extension ObjectSpecifierProtocol {

    func userProperty(_ name: String) -> ObjectSpecifier {
        return ObjectSpecifier(wantType: AE4.Descriptors.Types.property, selectorForm: AE4.Descriptors.IndexForms.userProperty, selectorData: NSAppleEventDescriptor(string: name), parentQuery: self, app: self.app)
    }

    func property(_ code: OSType) -> ObjectSpecifier {
		return ObjectSpecifier(wantType: AE4.Descriptors.Types.property, selectorForm: AE4.Descriptors.IndexForms.property, selectorData: NSAppleEventDescriptor(typeCode: code), parentQuery: self, app: self.app)
    }
    
    func property(_ code: String) -> ObjectSpecifier {
        let data: Any
        do {
            data = NSAppleEventDescriptor(typeCode: try FourCharCode(fourByteString: code))
        } catch {
            data = error
        }
        return ObjectSpecifier(wantType: AE4.Descriptors.Types.property, selectorForm: AE4.Descriptors.IndexForms.property, selectorData: data, parentQuery: self, app: self.app)
    }
    
    func elements(_ code: OSType) -> MultipleObjectSpecifier {
        return MultipleObjectSpecifier(wantType: NSAppleEventDescriptor(typeCode: code), selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: AE4.Descriptors.AbsolutePositions.all, parentQuery: self, app: self.app)
    }
    
    func elements(_ code: String) -> MultipleObjectSpecifier {
        let want: NSAppleEventDescriptor, data: Any
        do {
            want = NSAppleEventDescriptor(typeCode: try FourCharCode(fourByteString: code))
            data = AE4.Descriptors.AbsolutePositions.all
        } catch {
            want = NSAppleEventDescriptor.null()
            data = error
        } 
        return MultipleObjectSpecifier(wantType: want, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: data, parentQuery: self, app: self.app)
    }
    
    // relative position selectors
    func previous(_ elementClass: Symbol? = nil) -> ObjectSpecifier {
        return ObjectSpecifier(wantType: elementClass == nil ? self.wantType : elementClass!.encodeAEDescriptor(),
                                        selectorForm: AE4.Descriptors.IndexForms.relativePosition, selectorData: AE4.Descriptors.RelativePositions.previous,
                                        parentQuery: self, app: self.app)
    }
    
    func next(_ elementClass: Symbol? = nil) -> ObjectSpecifier {
        return ObjectSpecifier(wantType: elementClass == nil ? self.wantType : elementClass!.encodeAEDescriptor(),
                                        selectorForm: AE4.Descriptors.IndexForms.relativePosition, selectorData: AE4.Descriptors.RelativePositions.next,
                                        parentQuery: self, app: self.app)
    }
    
    // insertion specifiers
    var beginning: InsertionSpecifier {
        return InsertionSpecifier(insertionLocation: AE4.Descriptors.InsertionLocations.beginning, parentQuery: self, app: self.app)
    }
    var end: InsertionSpecifier {
        return InsertionSpecifier(insertionLocation: AE4.Descriptors.InsertionLocations.end, parentQuery: self, app: self.app)
    }
    var before: InsertionSpecifier {
        return InsertionSpecifier(insertionLocation: AE4.Descriptors.InsertionLocations.before, parentQuery: self, app: self.app)
    }
    var after: InsertionSpecifier {
        return InsertionSpecifier(insertionLocation: AE4.Descriptors.InsertionLocations.after, parentQuery: self, app: self.app)
    }
    
    var all: MultipleObjectSpecifier { // equivalent to `every REFERENCE`; applied to a property specifier, converts it to all-elements (this may be necessary when property and element names are identical, in which case [with exception of `text`] a property specifier is constructed by default); applied to an all-elements specifier, returns it as-is; applying it to any other reference form will throw an error when used
        if self.selectorForm.typeCodeValue == AE4.IndexForm.propertyID.rawValue {
            return MultipleObjectSpecifier(wantType: self.selectorData as! NSAppleEventDescriptor, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: AE4.Descriptors.AbsolutePositions.all, parentQuery: self.parentQuery, app: self.app)
        } else if
            self.selectorForm.typeCodeValue == AE4.IndexForm.absolutePosition.rawValue,
            (self.selectorData as? NSAppleEventDescriptor)?.enumCodeValue == AE4.AbsoluteOrdinal.all.rawValue,
            let specifier = self as? MultipleObjectSpecifier
        {
            return specifier
        } else {
            let error = AutomationError(code: 1, message: "Invalid specifier: \(self).all")
            return MultipleObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: error, parentQuery: self.parentQuery, app: self.app)
        }
    }
}

/******************************************************************************/
// Multi-element specifier; represents a one-to-many relationship between nodes in the app's AEOM graph

public class MultipleObjectSpecifier: ObjectSpecifier {}

extension MultipleObjectSpecifier {

    // Note: calling an element[s] selector on an all-elements specifier effectively replaces its original gAll selector data with the new selector data, instead of extending the specifier chain. This ensures that applying any selector to `elements[all]` produces `elements[selector]` (effectively replacing the existing selector), while applying a second selector to `elements[selector]` produces `elements[selector][selector2]` (appending the second selection to the first) as normal; e.g. `first document whose modified is true` would be written as `documents[Its.modified==true].first`.
    var baseQuery: Query {
        if
            let desc = self.selectorData as? NSAppleEventDescriptor,
            desc.descriptorType == AE4.Types.absoluteOrdinal && desc.enumCodeValue == AE4.AbsoluteOrdinal.all.rawValue
        {
            return self.parentQuery
        } else {
            return self
        }
    }
    
    // by-index, by-name, by-test
    public subscript(index: Any) -> ObjectSpecifier {
        var form: NSAppleEventDescriptor
        switch (index) {
        case is TestClause:
            return self[index as! TestClause]
        case is String:
            form = AE4.Descriptors.IndexForms.name
        default:
            form = AE4.Descriptors.IndexForms.absolutePosition
        }
        return ObjectSpecifier(wantType: self.wantType, selectorForm: form, selectorData: index, parentQuery: self.baseQuery, app: self.app)
    }

    public subscript(test: TestClause) -> MultipleObjectSpecifier {
        return MultipleObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.test, selectorData: test, parentQuery: self.baseQuery, app: self.app)
    }
    
    // by-name, by-id, by-range
    public func named(_ name: Any) -> ObjectSpecifier { // use this if name is not a String, else use subscript // TO DO: trying to think of a use case where this has ever been found necessary; DELETE? (see also TODOs on whether or not to add an explicit `all` selector property)
        return ObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.name, selectorData: name, parentQuery: self.baseQuery, app: self.app)
    }
    public func id(_ id: Any) -> ObjectSpecifier {
        return ObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.uniqueID, selectorData: id, parentQuery: self.baseQuery, app: self.app)
    }
    public subscript(from: Any, to: Any) -> MultipleObjectSpecifier {
        // caution: by-range specifiers must be constructed as `elements[from,to]`, NOT `elements[from...to]`, as `Range<T>` types are not supported
        // Note that while the `x...y` form _could_ be supported (via the SelfPacking protocol, since Ranges are generics), the `x..<y` form is problematic as it doesn't have a direct analog in Apple events (which are always inclusive of both start and end points). Automatically mapping `x..<y` to `x...y.previous()` is liable to cause its own set of problems, e.g. some apps may fail to resolve this more complex query correctly/at all), and it's hard to justify the additional complexity of having two different ways of constructing ranges, one of which brings various caveats and limitations, and the more complicated user documentation that will inevitably require.
        // Another concern is that supporting 'standard' Range syntax will further encourage users to lapse into using Swift-style zero-indexing (e.g. `0..<3`) instead of the correct Apple event one-indexing (`1 thru 3`) – it'll be hard enough keeping them right when using the single-element by-index syntax (where `elements[0]` is a common user error, and - worse - one that CocoaScripting intentionally indulges instead of reporting as an error, so that both `elements[0]` and `elements[1]` actually refer to the _same_ element, not consecutive elements as expected).
        return MultipleObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.range, selectorData: RangeSelector(start: from, stop: to, wantType: self.wantType), parentQuery: self.baseQuery, app: self.app)
    }
    
    // by-ordinal
    public var first: ObjectSpecifier {
        return ObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: AE4.Descriptors.AbsolutePositions.first, parentQuery: self.baseQuery, app: self.app)
    }
    public var middle: ObjectSpecifier {
        return ObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: AE4.Descriptors.AbsolutePositions.middle, parentQuery: self.baseQuery, app: self.app)
    }
    public var last: ObjectSpecifier {
        return ObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: AE4.Descriptors.AbsolutePositions.last, parentQuery: self.baseQuery, app: self.app)
    }
    public var any: ObjectSpecifier {
        return ObjectSpecifier(wantType: self.wantType, selectorForm: AE4.Descriptors.IndexForms.absolutePosition, selectorData: AE4.Descriptors.AbsolutePositions.any, parentQuery: self.baseQuery, app: self.app)
    }
}

// MARK: Targeted root construction
extension RootSpecifier {
    
    private convenience init(target: AETarget) {
        let app = App(target: target)
        self.init(.application, app: app)
    }
    
    public convenience init(name: String) {
        self.init(target: .name(name))
    }
    
    public convenience init(url: URL) {
        self.init(target: .url(url))
    }
    
    public convenience init(bundleIdentifier: String) {
        self.init(target: .bundleIdentifier(bundleIdentifier))
    }
    
    public convenience init(processIdentifier: pid_t) {
        self.init(target: .processIdentifier(processIdentifier))
    }
    
    public convenience init(addressDescriptor: NSAppleEventDescriptor) {
        self.init(target: .descriptor(addressDescriptor))
    }
    
}

// MARK: Utilities
extension RootSpecifier {
    
    /// Launches the target application, if any.
    public func launch() throws {
        try self.app.target.launch()
    }
    
    /// Whether the target application, if any, is currently running.
    public var isRunning: Bool {
        return self.app.target.isRunning
    }
    
    public func doTransaction<T>(session: Any? = nil, closure: () throws -> T) throws -> T {
        return try self.app.doTransaction(session: session, closure: closure)
    }
    
}

// MARK: Evaluation
extension ObjectSpecifier {
    
    public func get<Result>(_ directParameter: Any = NoParameter,
            requestedType: Symbol? = nil, waitReply: Bool = true, sendOptions: SendOptions? = nil,
            withTimeout: TimeInterval? = nil, ignoring: Considerations? = nil) throws -> Result {
        try self.app.sendAppleEvent(
            name: "get",
            eventClass: AE4.Suites.coreSuite,
            eventID: AE4.AESymbols.getData,
            parentSpecifier: self,
            directParameter: directParameter,
            keywordParameters: [],
            requestedType: requestedType,
            waitReply: waitReply,
            sendOptions: sendOptions,
            withTimeout: withTimeout,
            ignoring: ignoring
        )
    }
    
}
