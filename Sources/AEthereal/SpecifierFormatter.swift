//  Originally written by hhas.
//  See README.md for licensing information.

//
//  Generates source code representation of Specifier.
//

import Foundation
import AppKit

// Ian's notes: Formats SA specifiers as Swift expressions.
// Not really necessary for our purposes, but has potential debugging use.

// TO DO: when formatting specifiers, what info is needed? app?, isNestedSpecifier; anything else? (note, this data ought to be available throughout; e.g. given a list of specifiers, current nesting flag should be carried over; there is also the question of when to adopt specifier's own app vs use the one already provided to formatter; furthermore, it might be argued that App should do the formatting itself [although that leaves the flag problem])

// TO DO: how to display nested App root as shorthand? (really need separate description(nested:Bool) func, or else use visitor API - note that a simplified api only need replicate constructor calls, not individual specifier+selector method calls; it also gives cleaner approach to glue-specific hooks and dynamic use, and encapsulating general Swift type formatting)

// TO DO: when displaying by-range specifier's start and stop, simplify by-index/by-name representations where appropriate, e.g. `TextEdit().documents[TEDCon.documents[1], TEDCon.documents[-2]]` should display as `TextEdit().documents[1, -2]`

/******************************************************************************/
// Formatter

// used by a Specifier's description property to render Swift literal representation of itself;
// static glues instantiate this with their own application-specific code->name translation tables

public func formatAEtherealObject(_ object: Any) -> String {
    switch object {
    case let obj as RootSpecifier:
        return formatRootSpecifier(obj)
    case let obj as InsertionSpecifier:
        return formatInsertionSpecifier(obj)
    case let obj as SingleObjectSpecifier:
        return formatObjectSpecifier(obj)
    case let obj as ComparisonTest:
        return formatComparisonTest(obj)
    case let obj as LogicalTest:
        return formatLogicalTest(obj)
    case let obj as Symbol:
        return "Symbol(code:\(formatFourCharCodeString(obj.code)), type:\(formatFourCharCodeString(obj.type.rawValue)))"
    default:
        return formatValue(object)
    }
}

// Specifier formatters

func formatRootSpecifier(_ specifier: RootSpecifier) -> String {
    switch specifier.kind {
    case .application:
        var result = "Application"
        switch specifier.app.target {
        case .none:
            result = "«application»"
        case .current:
            result += ".currentApplication()"
        case .name(let name):
            result += "(name: \(formatAEtherealObject(name)))"
        case .url(let url):
            result += url.isFileURL ? "(name: \(formatAEtherealObject(url.path)))" : "(url: \(formatAEtherealObject(url)))"
        case .bundleIdentifier(let bundleID):
            result += "(bundleIdentifier: \(formatAEtherealObject(bundleID)))"
        case .processIdentifier(let pid):
            result += "(processIdentifier: \(pid))"
        case .descriptor(let desc):
            result += "(addressDescriptor: \(desc))"
        }
        return result
    case .container:
        return "«container»"
    case .specimen:
        return "«specimen»"
    case let .object(descriptor):
        return "«object root: \(descriptor)»"
    }
}

func formatInsertionSpecifier(_ specifier: InsertionSpecifier) -> String {
    if let name: String = {
        switch specifier.insertionLocation {
        case .beginning:
            return "beginning"
        case .end:
            return "end"
        case .before:
            return "before"
        case .after:
            return "after"
        }
    }() {
        return "\(formatAEtherealObject(specifier.parentQuery)).\(name)"
    }
    return "<\(type(of: specifier))(kpos:\(specifier.insertionLocation),kobj:\(formatAEtherealObject(specifier.parentQuery)))>"
}

func formatObjectSpecifier(_ specifier: SingleObjectSpecifier) -> String {
    var result = formatAEtherealObject(specifier.parentQuery)
    switch specifier.selectorForm {
    case .propertyID:
        // kludge, seld is either desc or symbol, depending on whether constructed or deocded; TO DO: eliminate?
        if let desc = specifier.selectorData as? AEDescriptor, let propertyDesc = desc.coerce(to: .type) {
            return result + ".property(\(formatFourCharCodeString(propertyDesc.typeCodeValue)))"
        } else if let symbol = specifier.selectorData as? Symbol {
            return result + ".property(\(formatFourCharCodeString(symbol.code)))"
        } // else malformed desc
    case .userPropertyID:
        return "\(result).userProperty(\(formatValue(specifier.selectorData)))"
    case .relativePosition: // specifier.previous/next(SYMBOL)
        if let seld = specifier.selectorData as? AEDescriptor, // ObjectSpecifier's self-decoding does not decode ordinals
                let name = [AE4.RelativeOrdinal.previous.rawValue: "previous", AE4.RelativeOrdinal.next.rawValue: "next"][seld.enumCodeValue],
                let parent = specifier.parentQuery as? SingleObjectSpecifier {
            if specifier.wantType == parent.wantType {
                return "\(result).\(name)()" // use shorthand form for neatness
            } else {
                let element = "Symbol(code:\(formatFourCharCodeString(specifier.wantType.rawValue)), type:\(AE4.AEType.type.rawValue)))"
                return "\(result).\(name)(\(element))"
            }
        }
    default:
        result += ".elements(\(formatFourCharCodeString(specifier.wantType.rawValue)))"
        if let desc = specifier.selectorData as? AEDescriptor, desc.typeCodeValue == AE4.AbsoluteOrdinal.all.rawValue {
            return result
        }
        switch specifier.selectorForm {
        case .absolutePosition: // specifier[IDX] or specifier.first/middle/last/any
            if
                let desc = specifier.selectorData as? AEDescriptor, // ObjectSpecifier's self-decoding does not decode ordinals
                let ordinal: String = {
                    switch AE4.AbsoluteOrdinal(rawValue: desc.enumCodeValue) {
                    case .first:
                        return "first"
                    case .middle:
                        return "middle"
                    case .last:
                        return "last"
                    case .random:
                        return "any"
                    case .all, nil:
                        return nil
                    }
                }()
            {
                return "\(result).\(ordinal)"
            } else {
                return "\(result)[\(formatValue(specifier.selectorData))]"
            }
        case .name: // specifier[NAME] or specifier.named(NAME)
            return specifier.selectorData is Int ? "\(result).named(\(formatValue(specifier.selectorData)))"
                                                 : "\(result)[\(formatValue(specifier.selectorData))]"
        case .uniqueID: // specifier.ID(UID)
            return "\(result).ID(\(formatAEtherealObject(specifier.selectorData)))"
        case .range: // specifier[FROM,TO]
            if let seld = specifier.selectorData as? RangeSelector {
                return "\(result)[\(formatAEtherealObject(seld.start)), \(formatAEtherealObject(seld.stop))]" // TO DO: app-based specifiers should use untargeted 'App' root; con-based specifiers should be reduced to minimal representation if their wantType == specifier.wantType
            }
        case .test: // specifier[TEST]
            return "\(result)[\(formatAEtherealObject(specifier.selectorData))]"
        default:
            break
        }
    }
    return "<\(type(of: specifier))(want:\(specifier.wantType),form:\(specifier.selectorForm),seld:\(formatValue(specifier.selectorData)),from:\(formatAEtherealObject(specifier.parentQuery)))>"
}

private let _comparisonOperators = [AE4.Comparison.lessThan: "<", AE4.Comparison.lessThanEquals: "<=", AE4.Comparison.equals: "==",
                                    AE4.Comparison.greaterThan: ">", AE4.Comparison.greaterThanEquals: ">=", AE4.Comparison.beginsWith: "beginsWith", AE4.Comparison.endsWith: "endsWith", AE4.Comparison.contains: "contains"]
private let _logicalBinaryOperators = [AE4.LogicalOperator.and: "and", AE4.LogicalOperator.or: "or"]
private let _logicalUnaryOperators = [AE4.LogicalOperator.not: "not"]

func formatComparisonTest(_ specifier: ComparisonTest) -> String {
    let operand1 = formatValue(specifier.operand1)
    let operand2 = formatValue(specifier.operand2)
    let comparison = specifier.operatorType
    if let name = _comparisonOperators[comparison] {
        return "\(operand1) \(name) \(operand2)"
    }
    return "<\(type(of: specifier))(relo:\(specifier.operatorType),obj1:\(formatValue(operand1)),obj2:\(formatValue(operand2)))>"
}

func formatLogicalTest(_ specifier: LogicalTest) -> String {
    let operands = specifier.operands.map(formatValue(_:))
    let logical = specifier.operatorType
    if let name = _logicalBinaryOperators[logical], operands.count > 1 {
        return operands.joined(separator: " \(name) ")
    }
    if let name = _logicalUnaryOperators[logical], operands.count == 1 {
        return "\(name) (\(operands[0]))"
    }
    return "<\(type(of: specifier))(logc:\(specifier.operatorType),term:\(formatValue(operands)))>"
}

// general formatting functions

func formatValue(_ value: Any) -> String { // TO DO: this should probably be a method on SpecifierFormatter so that it can be overridden to generate representations for other languages
    // formats AE-bridged Swift types as literal syntax; other Swift types will show their default description (unfortunately debugDescription doesn't provide usable literal representations - e.g. String doesn't show tabs in escaped form, Cocoa classes return their [non-literal] description string instead, and reliable representations of Bool/Int/Double are a dead loss as soon as NSNumber gets involved, so custom implementation is needed)
    switch value {
    case let obj as NSArray: // HACK (since `obj as Array` won't work); see also App.encode() // TO DO: implement SelfFormatting protocol on Array, Set, Dictionary
        return "[" + obj.map({formatValue($0)}).joined(separator: ", ") + "]"
    case let obj as NSDictionary: // HACK; see also App.encode()
        return "[" + obj.map({"\(formatValue($0)): \(formatValue($1))"}).joined(separator: ", ") + "]"
    case let obj as String:
        return obj.debugDescription
    case let obj as Date:
        return "Date(timeIntervalSinceReferenceDate:\(obj.timeIntervalSinceReferenceDate)) /*\(obj.description)*/"
    case let obj as URL:
        if obj.isFileURL {
            return "URL(fileURLWithPath:\(formatValue(obj.path)))"
        } else {
            return "URL(string:\(formatValue(obj.absoluteString)))"
        }
    case let obj as NSNumber:
        // note: matching Bool, Int, Double types can be glitchy due to Swift's crappy bridging of ObjC's crappy NSNumber class,
        // so just match NSNumber (which also matches corresponding Swift types) and figure out appropriate representation
        if CFBooleanGetTypeID() == CFGetTypeID(obj) { // voodoo: NSNumber class cluster uses __NSCFBoolean
            return obj == 0 ? "false" : "true"
        } else {
            return "\(value)"
        }
    default:
        return "\(value)" // SwiftAutomation objects (specifiers, symbols) are self-formatting; any other value will use its own default description (which may or may not be the same as its literal representation, but that's Swift's problem, not ours)
    }
}

public func formatCommand(_ description: CommandDescription, applicationObject: RootSpecifier? = nil) -> String {
    var parentSpecifier = applicationObject != nil ? String(describing: applicationObject!) : "Application()"
    var args: [String] = []
    switch description.signature {
    case .named(let name, let directParameter, let keywordParameters, let requestedType):
        if description.subject != nil && parameterExists(directParameter) {
            parentSpecifier = formatAEtherealObject(description.subject!)
            args.append(formatAEtherealObject(directParameter))
            //} else if eventClass == _kAECoreSuite && eventID == _kAECreateElement { // TO DO: format make command as special case (for convenience, sendAppleEvent should allow user to call `make` directly on a specifier, in which case the specifier is used as its `at` parameter if not already given)
        } else if description.subject == nil && parameterExists(directParameter) {
            parentSpecifier = formatAEtherealObject(directParameter)
        } else if description.subject != nil && !parameterExists(directParameter) {
            parentSpecifier = formatAEtherealObject(description.subject!)
        }
        parentSpecifier += ".\(name)"
        for (key, value) in keywordParameters { args.append("\(key): \(formatAEtherealObject(value))") }
        if let symbol = requestedType { args.append("requestedType: \(symbol)") }
    case .codes(let eventClass, let eventID, let parameters):
        if let subject = description.subject {
            parentSpecifier = formatAEtherealObject(subject)
        }
        parentSpecifier += ".sendAppleEvent"
        args.append("\(formatFourCharCodeString(eventClass)), \(formatFourCharCodeString(eventID))")
        if parameters.count > 0 {
            let params = parameters.map({ "\(formatFourCharCodeString($0)): \(formatAEtherealObject($1)))" }).joined(separator: ", ")
            args.append("[\(params)]")
        }
    }
    // TO DO: AE's representation of AESendMessage args (waitReply and withTimeout) is unreliable; may be best to ignore these entirely
    /*
     if !eventDescription.waitReply {
     args.append("waitReply: false")
     }
     //sendOptions: NSAppleEventSendOptions? = nil
     if eventDescription.withTimeout != defaultTimeout {
     args.append("withTimeout: \(eventDescription.withTimeout)") // TO DO: if -2, use NoTimeout constant (except 10.11 hasn't defined one yet, and is still buggy in any case)
     }
     */
    if description.ignoring != defaultIgnoring {
        args.append("ignoring: \(description.ignoring)")
    }
    return "try \(parentSpecifier)(\(args.joined(separator: ", ")))"
}

/******************************************************************************/

// convert an AE4 to its String literal representation, e.g. 'docu' -> "\"docu\""
func formatFourCharCodeString(_ code: AE4) -> String {
    var n = CFSwapInt32HostToBig(code)
    var result = ""
    for _ in 1...4 {
        let c = n % 256
        result += String(format: (c == 0x21 || 0x23 <= c && c <= 0x7e) ? "%c" : "\\0x%02X", c)
        n >>= 8
    }
    return "\"\(result)\""
}
