//  Originally written by hhas.
//  See README.md for licensing information.

import AppKit.NSWorkspace
import Foundation

public typealias LaunchOptions = NSWorkspace.LaunchOptions
public typealias SendOptions = AEDescriptor.SendOptions

/// How to behave if a target that is not running is supposed to be sent
/// an AppleEvent.
public enum RelaunchMode {
    /// Always attempt to relaunch.
    case always
    /// Attempt to relaunch only for "run" or "launch" events.
    case limited
    /// Never attempt to relaunch.
    case never
}

public var launchOptions: LaunchOptions = [.withoutActivation]
public var relaunchMode: RelaunchMode = .limited

// if target process is no longer running, Apple Event Manager will return an error when an event is sent to it
private let errorCodesThatTriggerRelaunch: Set<Int> = [-600, -609]
// if relaunchMode = .limited, only 'launch' and 'run' are allowed to restart a local application that's been quit
private let limitedRelaunchEvents: [(AE4,AE4)] = [(AE4.Events.Core.eventClass, AE4.Events.Core.IDs.openApplication), (AE4.Events.AppleScript.eventClass, AE4.Events.AppleScript.IDs.launch)]

public typealias KeywordParameters = [AE4 : Encodable]

extension App {
    
    /// Sends an AppleScript-compatible AppleEvent with the (many available)
    /// given options.
    @discardableResult
    public func sendAppleEvent(
        eventClass: AE4,
        eventID: AE4,
        targetQuery: Query = .rootSpecifier(.application), // the query on which the command method was called; see special-case encoding logic below
        parameters: KeywordParameters = [:],
        requestedType: AE4.AEType? = nil, // event's `as` parameter, if any (note: while a `keyAERequestedType` parameter can be supplied via `keywordParameters:`, it will be ignored if `requestedType:` is given)
        sendOptions: SendOptions = [.alwaysInteract, .waitForReply],
        timeout: TimeInterval = 120,
        considering: Considerations? = nil,
        ignoring: Considerations? = nil
    ) throws -> AEDescriptor
    {
        // Used in catch block at the bottom:
        var sentEvent: AEDescriptor?, repliedEvent: AEDescriptor?
        
        do {
            // Create a new AppleEvent descriptor (throws ConnectionError if target app isn't found)
            let event = AEDescriptor(eventClass: eventClass, eventID: eventID, target: try self.targetDescriptor())
            // encode its keyword parameters
            for (code, value) in parameters {
                do {
                    event.setDescriptor(try AEEncoder.encode(value), forKeyword: code)
                } catch {
                    throw AutomationError(code: error._code, message: "Invalid '\(String(ae4Code: code))' parameter.", cause: error)
                }
            }
            
            if let direct = parameters[AE4.Keywords.directObject] {
                event[AE4.Keywords.directObject] = try AEEncoder.encode(direct)
            }
            
            if case .rootSpecifier = targetQuery {
            } else {
                if eventClass == AE4.Suites.coreSuite && eventID == AE4.AESymbols.createElement {
                    event[.subject] = try AEEncoder.encode(targetQuery)
                } else {
                    if parameters[AE4.Keywords.directObject] == nil {
                        event[AE4.Keywords.directObject] = try AEEncoder.encode(targetQuery)
                    } else {
                        event[.subject] = try AEEncoder.encode(targetQuery)
                    }
                }
            }
            
            if let type = requestedType {
                event[AE4.Keywords.requestedType] = AEDescriptor(typeCode: type)
            }
            
            let consideringIgnoring = AEthereal.encode(considering: defaultConsidering, ignoring: ignoring ?? defaultIgnoring)
            event[.considsAndIgnores] = consideringIgnoring
            
            var replyEvent: AEDescriptor
            do {
                sentEvent = event
                replyEvent = try event.sendEvent(options: sendOptions, timeout: timeout)
                repliedEvent = replyEvent
            } catch {
                // handle errors raised by Apple Event Manager (e.g. timeout, process not found)
                if errorCodesThatTriggerRelaunch.contains((error as NSError).code) && self.target.isRelaunchable && (relaunchMode == .always
                        || (relaunchMode == .limited && limitedRelaunchEvents.contains(where: {$0.0 == eventClass && $0.1 == eventID}))) {
                    // event failed as target process has quit since previous event; recreate AppleEvent with new address and resend
                    self._targetDescriptor = nil
                    let copiedEvent = AEDescriptor(eventClass: eventClass, eventID: eventID, target: try self.targetDescriptor())
                    if event.numberOfItems > 0 {
                        for i in 1...event.numberOfItems {
                            copiedEvent[event.keywordForDescriptor(at: i)] = event.atIndex(i)!
                        }
                    }
                    for attribute in [AE4.Attribute.subject, AE4.Attribute.considsAndIgnores] {
                        if let value = event[attribute] {
                            copiedEvent[attribute] = value
                        }
                    }
                    sentEvent = copiedEvent
                    replyEvent = try copiedEvent.sendEvent(options: sendOptions, timeout: timeout)
                    repliedEvent = replyEvent
                } else {
                    throw error
                }
            }
            if sendOptions.contains(.waitForReply) {
                if
                    let errorNumber = replyEvent[AE4.Keywords.errorNumber]?.int32Value,
                    errorNumber != 0
                {
                    throw AutomationError(code: Int(errorNumber))
                } else if let resultDesc = replyEvent[AE4.Keywords.directObject] {
                    return resultDesc
                }
                return .missingValue
            } else if sendOptions.contains(.queueReply) {
                // get the return ID that will be used by the reply event so that client code's main loop can identify that reply event in its own event queue later on
                guard let returnIDDesc = event[.returnID] else {
                    throw AutomationError(code: 1, message: "Can't get return ID.")
                }
                return returnIDDesc
            }
            return .missingValue
        } catch {
            throw SendFailure(app: self, event: sentEvent, reply: repliedEvent, cause: error)
        }
    }
}


// MARK: -- Target encoding
extension App {
    
    public func targetDescriptor() throws -> AEDescriptor? {
        if _targetDescriptor == nil {
            _targetDescriptor = try target.descriptor([.withoutActivation])
        }
        return _targetDescriptor
    }
    
}
