// See README.md for licensing information.

// MARK: Chained object specifier construction
public protocol ChainableSpecifier {
    
    func byProperty(_ property: AE4.AEEnum) -> ObjectSpecifier
    func byUserProperty(_ userProperty: String) -> ObjectSpecifier
    func byIndex(_ wantType: AE4.AEType, _ index: Int) -> ObjectSpecifier
    func byAbsolute(_ wantType: AE4.AEType, _ absolute: AE4.AbsoluteOrdinal) -> ObjectSpecifier
    func byRelative(_ wantType: AE4.AEType, _ relative: AE4.RelativeOrdinal) -> ObjectSpecifier
    func byName(_ wantType: AE4.AEType, _ name: String) -> ObjectSpecifier
    func byID(_ wantType: AE4.AEType, _ id: Codable) -> ObjectSpecifier
    func byRange(_ wantType: AE4.AEType, from: Codable, thru: Codable) -> ObjectSpecifier
    func byTest(_ wantType: AE4.AEType, _ test: ObjectSpecifier.TestClause) -> ObjectSpecifier
    
    func insertion(at location: AE4.InsertionLocation) -> InsertionSpecifier
}

extension ObjectSpecifier: ChainableSpecifier {
    
    public func byProperty(_ property: AE4.AEEnum) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: .property, selectorForm: .property(property))
    }
    public func byUserProperty(_ userProperty: String) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: .property, selectorForm: .userProperty(userProperty))
    }
    public func byIndex(_ wantType: AE4.AEType, _ index: Int) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .index(index))
    }
    public func byAbsolute(_ wantType: AE4.AEType, _ absolute: AE4.AbsoluteOrdinal) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .absolute(absolute))
    }
    public func byRelative(_ wantType: AE4.AEType, _ relative: AE4.RelativeOrdinal) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .relative(relative))
    }
    public func byName(_ wantType: AE4.AEType, _ name: String) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .name(name))
    }
    public func byID(_ wantType: AE4.AEType, _ id: Codable) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .id(id))
    }
    public func byRange(_ wantType: AE4.AEType, from: Codable, thru: Codable) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .range(RangeSelector(start: from, stop: thru)))
    }
    public func byTest(_ wantType: AE4.AEType, _ test: TestClause) -> ObjectSpecifier {
        ObjectSpecifier(parent: .objectSpecifier(self), wantType: wantType, selectorForm: .test(test))
    }
    
    public func insertion(at location: AE4.InsertionLocation) -> InsertionSpecifier {
        InsertionSpecifier(parent: .objectSpecifier(self), insertionLocation: location)
    }
    
}

extension RootSpecifier: ChainableSpecifier {
    
    public func byProperty(_ property: AE4.AEEnum) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: .property, selectorForm: .property(property))
    }
    public func byUserProperty(_ userProperty: String) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: .property, selectorForm: .userProperty(userProperty))
    }
    public func byIndex(_ wantType: AE4.AEType, _ index: Int) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .index(index))
    }
    public func byAbsolute(_ wantType: AE4.AEType, _ absolute: AE4.AbsoluteOrdinal) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .absolute(absolute))
    }
    public func byRelative(_ wantType: AE4.AEType, _ relative: AE4.RelativeOrdinal) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .relative(relative))
    }
    public func byName(_ wantType: AE4.AEType, _ name: String) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .name(name))
    }
    public func byID(_ wantType: AE4.AEType, _ id: Codable) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .id(id))
    }
    public func byRange(_ wantType: AE4.AEType, from: Codable, thru: Codable) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .range(ObjectSpecifier.RangeSelector(start: from, stop: thru)))
    }
    public func byTest(_ wantType: AE4.AEType, _ test: ObjectSpecifier.TestClause) -> ObjectSpecifier {
        ObjectSpecifier(parent: .rootSpecifier(self), wantType: wantType, selectorForm: .test(test))
    }
    
    public func insertion(at location: AE4.InsertionLocation) -> InsertionSpecifier {
        InsertionSpecifier(parent: .rootSpecifier(self), insertionLocation: location)
    }
    
}

// MARK: Test clause construction
extension ObjectSpecifier {
    
    public func beginsWith(_ value: Codable) -> TestClause {
        .comparison(operator: .beginsWith, lhs: self, rhs: value)
    }

    public func endsWith(_ value: Codable) -> TestClause {
        .comparison(operator: .endsWith, lhs: self, rhs: value)
    }

    public func contains(_ value: Codable) -> TestClause {
        .comparison(operator: .contains, lhs: self, rhs: value)
    }

    public func isIn(_ value: Codable) -> TestClause {
        .comparison(operator: .contains, lhs: value, rhs: self)
    }
    
}

public func <(lhs: ObjectSpecifier, rhs: Codable) -> ObjectSpecifier.TestClause {
    .comparison(operator: .lessThan, lhs: lhs, rhs: rhs)
}

public func <=(lhs: ObjectSpecifier, rhs: Codable) -> ObjectSpecifier.TestClause {
    .comparison(operator: .lessThanEquals, lhs: lhs, rhs: rhs)
}

public func ==(lhs: ObjectSpecifier, rhs: Codable) -> ObjectSpecifier.TestClause {
    .comparison(operator: .equals, lhs: lhs, rhs: rhs)
}

public func !=(lhs: ObjectSpecifier, rhs: Codable) -> ObjectSpecifier.TestClause {
    .logicalUnary(operator: .not, operand: lhs == rhs)
}

public func >(lhs: ObjectSpecifier, rhs: Codable) -> ObjectSpecifier.TestClause {
    .comparison(operator: .greaterThan, lhs: lhs, rhs: rhs)
}

public func >=(lhs: ObjectSpecifier, rhs: Codable) -> ObjectSpecifier.TestClause {
    .comparison(operator: .greaterThanEquals, lhs: lhs, rhs: rhs)
}

public func &&(lhs: ObjectSpecifier.TestClause, rhs: ObjectSpecifier.TestClause) -> ObjectSpecifier.TestClause {
    .logicalBinary(operator: .and, lhs: lhs, rhs: rhs)
}

public func ||(lhs: ObjectSpecifier.TestClause, rhs: ObjectSpecifier.TestClause) -> ObjectSpecifier.TestClause {
    .logicalBinary(operator: .or, lhs: lhs, rhs: rhs)
}

public prefix func !(op: ObjectSpecifier.TestClause) -> ObjectSpecifier.TestClause {
    .logicalUnary(operator: .not, operand: op)
}
