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

extension Specifier {

    public func userProperty(_ name: String) -> SingleObjectSpecifier {
        SingleObjectSpecifier(wantType: .property, selectorForm: .userPropertyID, selectorData: name, parentQuery: self, app: app)
    }

    public func property(_ code: AE4) -> SingleObjectSpecifier {
		SingleObjectSpecifier(wantType: .property, selectorForm: .propertyID, selectorData: AEDescriptor(typeCode: code), parentQuery: self, app: app)
    }
    
    public func elements(_ code: AE4.AEType) -> MultipleObjectSpecifier {
        MultipleObjectSpecifier(wantType: code, selectorForm: .absolutePosition, selectorData: AE4.AbsoluteOrdinal.all, parentQuery: self, app: app)
    }
    
    public var beginning: InsertionSpecifier {
        InsertionSpecifier(insertionLocation: .beginning, parentQuery: self, app: app)
    }
    public var end: InsertionSpecifier {
        InsertionSpecifier(insertionLocation: .end, parentQuery: self, app: app)
    }
    public var before: InsertionSpecifier {
        InsertionSpecifier(insertionLocation: .before, parentQuery: self, app: app)
    }
    public var after: InsertionSpecifier {
        InsertionSpecifier(insertionLocation: .after, parentQuery: self, app: app)
    }
    
}

extension ObjectSpecifier {
    
    public func previous(_ elementClass: AE4.AEType? = nil) -> SingleObjectSpecifier {
        SingleObjectSpecifier(wantType: elementClass ?? wantType, selectorForm: .relativePosition, selectorData: AE4.RelativeOrdinal.previous, parentQuery: self, app: app)
    }
    public func next(_ elementClass: AE4.AEType? = nil) -> SingleObjectSpecifier {
        SingleObjectSpecifier(wantType: elementClass ?? wantType, selectorForm: .relativePosition, selectorData: AE4.RelativeOrdinal.next, parentQuery: self, app: app)
    }
    
}

public class MultipleObjectSpecifier: SingleObjectSpecifier {}

extension MultipleObjectSpecifier {
    
    public func index(_ index: AEEncodable) -> SingleObjectSpecifier {
        SingleObjectSpecifier(wantType: wantType, selectorForm: .absolutePosition, selectorData: index, parentQuery: self, app: app)
    }
    public func named(_ name: AEEncodable) -> SingleObjectSpecifier {
        SingleObjectSpecifier(wantType: wantType, selectorForm: .name, selectorData: name, parentQuery: self, app: app)
    }
    public func id(_ id: AEEncodable) -> SingleObjectSpecifier {
        return SingleObjectSpecifier(wantType: wantType, selectorForm: .uniqueID, selectorData: id, parentQuery: self, app: app)
    }
    
    public var first: SingleObjectSpecifier {
        return SingleObjectSpecifier(wantType: wantType, selectorForm: .absolutePosition, selectorData: AE4.AbsoluteOrdinal.first, parentQuery: self, app: app)
    }
    public var middle: SingleObjectSpecifier {
        return SingleObjectSpecifier(wantType: wantType, selectorForm: .absolutePosition, selectorData: AE4.AbsoluteOrdinal.middle, parentQuery: self, app: app)
    }
    public var last: SingleObjectSpecifier {
        return SingleObjectSpecifier(wantType: wantType, selectorForm: .absolutePosition, selectorData: AE4.AbsoluteOrdinal.last, parentQuery: self, app: app)
    }
    public var any: SingleObjectSpecifier {
        return SingleObjectSpecifier(wantType: wantType, selectorForm: .absolutePosition, selectorData: AE4.AbsoluteOrdinal.random, parentQuery: self, app: app)
    }
    
    public func range(from: AEEncodable, to: AEEncodable) -> MultipleObjectSpecifier {
        return MultipleObjectSpecifier(wantType: wantType, selectorForm: .range, selectorData: RangeSelector(start: from, stop: to, wantType: wantType), parentQuery: self, app: app)
    }
    
    public func test(_ testClause: TestClause) -> SingleObjectSpecifier {
        SingleObjectSpecifier(wantType: wantType, selectorForm: .test, selectorData: testClause, parentQuery: self, app: app)
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
    
    public convenience init(addressDescriptor: AEDescriptor) {
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
    
}

// MARK: Evaluation
extension SingleObjectSpecifier {
    
    public func get(
        _ directParameter: Any = NoParameter,
        requestedType: Symbol? = nil,
        waitReply: Bool = true,
        sendOptions: SendOptions? = nil,
        timeout: TimeInterval? = nil,
        ignoring: Considerations? = nil
    ) throws -> AEValue
    {
        try self.app.sendAppleEvent(
            eventClass: AE4.Suites.coreSuite,
            eventID: AE4.AESymbols.getData,
            targetSpecifier: self,
            directParameter: directParameter,
            keywordParameters: [],
            requestedType: requestedType,
            waitReply: waitReply,
            sendOptions: sendOptions,
            timeout: timeout,
            ignoring: ignoring
        )
    }
    
}
