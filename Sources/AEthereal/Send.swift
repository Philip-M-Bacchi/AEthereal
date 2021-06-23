//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

// TO DO: get rid of waitReply: arg and just pass .ignoreReply to sendOptions (if ignore/wait/queue option not given, add .waitReply by default)

private let launchOptions: LaunchOptions = DefaultLaunchOptions
private let relaunchMode: RelaunchMode = DefaultRelaunchMode

let defaultTimeout: TimeInterval = 120 // bug workaround: NSAppleEventDescriptor.sendEvent(options:timeout:) method's support for kAEDefaultTimeout=-1 and kNoTimeOut=-2 flags is buggy <rdar://21477694>, so for now the default timeout is hardcoded here as 120sec (same as in AS)

// if target process is no longer running, Apple Event Manager will return an error when an event is sent to it
private let RelaunchableErrorCodes: Set<Int> = [-600, -609]
// if relaunchMode = .limited, only 'launch' and 'run' are allowed to restart a local application that's been quit
private let LimitedRelaunchEvents: [(OSType,OSType)] = [(AE4.Events.Core.eventClass, AE4.Events.Core.IDs.openApplication), (AE4.Events.AppleScript.eventClass, AE4.Events.AppleScript.IDs.launch)]

public typealias KeywordParameter = (code: OSType, value: Any)

// MARK: Apple event sending
extension App {
    
    /// Sends an AppleScript-compatible AppleEvent with the (many available)
    /// given options.
    @discardableResult
    public func sendAppleEvent(
        eventClass: OSType,
        eventID: OSType,
        targetSpecifier: Specifier,
        parameters: [OSType:Any] = [:],
        requestedType: Symbol? = nil,
        waitReply: Bool = true,
        sendOptions: SendOptions? = nil,
        timeout: TimeInterval? = nil,
        considering: Considerations? = nil,
        ignoring: Considerations? = nil
    ) throws -> AEValue {
        var parameters = parameters
        let directParameter = parameters.removeValue(forKey: AE4.Keywords.directObject) ?? NoParameter
        let keywordParameters: [KeywordParameter] = parameters.map { (code: $0, value: $1) }
        return try self.sendAppleEvent(
            eventClass: eventClass,
            eventID: eventID,
            targetSpecifier: targetSpecifier,
            directParameter: directParameter,
            keywordParameters: keywordParameters,
            requestedType: requestedType,
            waitReply: waitReply,
            sendOptions: sendOptions,
            timeout: timeout,
            considering: considering,
            ignoring: ignoring
        )
    }
    
    /// Sends an AppleScript-compatible AppleEvent with the (many available)
    /// given options.
    @discardableResult
    public func sendAppleEvent(
        eventClass: OSType,
        eventID: OSType,
        targetSpecifier: Specifier, // the Specifier on which the command method was called; see special-case encoding logic below
        directParameter: Any = NoParameter, // the first (unnamed) parameter to the command method; see special-case encoding logic below
        keywordParameters: [KeywordParameter] = [], // the remaining named parameters
        requestedType: Symbol? = nil, // event's `as` parameter, if any (note: while a `keyAERequestedType` parameter can be supplied via `keywordParameters:`, it will be ignored if `requestedType:` is given)
        waitReply: Bool = true, // wait for application to respond before returning?
        sendOptions: SendOptions? = nil, // raw send options (these are rarely needed); if given, `waitReply:` is ignored
        timeout: TimeInterval? = nil, // no. of seconds to wait before raising timeout error (-1712); may also be default/never
        considering: Considerations? = nil,
        ignoring: Considerations? = nil
    ) throws -> AEValue
    {
        // note: human-readable command and parameter names are only used (if known) in error messages
        // note: all errors occurring within this method are caught and rethrown as CommandError, allowing error message to provide a description of the failed command as well as the error itself
        var sentEvent: NSAppleEventDescriptor?, repliedEvent: NSAppleEventDescriptor?
        do {
            // Create a new AppleEvent descriptor (throws ConnectionError if target app isn't found)
            let event = NSAppleEventDescriptor(eventClass: eventClass, eventID: eventID, targetDescriptor: try self.targetDescriptor(), returnID: AE4.autoGenerateReturnID, transactionID: AE4.anyTransactionID)
            // encode its keyword parameters
            for (code, value) in keywordParameters where parameterExists(value) {
                do {
                    event.setDescriptor(try self.encode(value), forKeyword: code)
                } catch {
                    throw AutomationError(code: error._code, message: "Invalid '\(String(fourCharCode: code))' parameter.", cause: error)
                }
            }
            
            let hasDirectParameter = parameterExists(directParameter)
            if hasDirectParameter {
                event.setParam(try self.encode(directParameter), forKeyword: AE4.Keywords.directObject)
            }
            
            var subject = applicationRoot
            if !(targetSpecifier is RootSpecifier) { // technically Application, but there isn't an explicit class for that
                if eventClass == AE4.Suites.coreSuite && eventID == AE4.AESymbols.createElement { // for user's convenience, `make` command is treated as a special case
                    // if `make` command is called on a specifier, use that specifier as event's `at` parameter if not already given
                    if event.paramDescriptor(forKeyword: AE4.Keywords.insertHere) != nil { // an `at` parameter was already given, so encode parent specifier as event's subject attribute
                        subject = try self.encode(targetSpecifier)
                    } else { // else encode parent specifier as event's `at` parameter and use null as event's subject attribute
                        event.setParam(try self.encode(targetSpecifier), forKeyword: AE4.Keywords.insertHere)
                    }
                } else { // for all other commands, check if a direct parameter was already given
                    if hasDirectParameter { // encode the parent specifier as the event's subject attribute
                        subject = try self.encode(targetSpecifier)
                    } else { // else encode parent specifier as event's direct parameter and use null as event's subject attribute
                        event.setParam(try self.encode(targetSpecifier), forKeyword: AE4.Keywords.directObject)
                    }
                }
            }
            event.setAttribute(subject, forKeyword: AE4.Attributes.subject)
            
            // encode requested type (`as`) parameter, if specified; note: most apps ignore this, but a few may recognize it (usually in `get` commands)  even if they don't define it in their dictionary (another AppleScript-introduced quirk); e.g. `Finder().home.get(requestedType:FIN.alias) as URL` tells Finder to return a typeAlias descriptor instead of typeObjectSpecifier, which can then be decoded as URL
            if let type = requestedType {
                event.setDescriptor(NSAppleEventDescriptor(typeCode: type.code), forKeyword: AE4.Keywords.requestedType)
            }
            
            // note: most apps ignore considering/ignoring attributes, and always ignore case and consider everything else
            let consideringIgnoring = AEthereal.encode(considering: defaultConsidering, ignoring: ignoring ?? defaultIgnoring)
            event.setAttribute(consideringIgnoring, forKeyword: AE4.Attributes.considsAndIgnores)
            
            // send the event
            let sendMode: SendOptions = [.alwaysInteract, .waitForReply] //sendOptions ?? defaultSendMode.union(waitReply ? .waitForReply : .noReply)
            let timeout = timeout ?? defaultTimeout
            var replyEvent: NSAppleEventDescriptor
            sentEvent = event
            do {
                replyEvent = try self.send(event: event, sendMode: sendMode, timeout: timeout) // throws NSError on AEM error
            } catch { // handle errors raised by Apple Event Manager (e.g. timeout, process not found)
                if RelaunchableErrorCodes.contains((error as NSError).code) && self.target.isRelaunchable && (relaunchMode == .always
                        || (relaunchMode == .limited && LimitedRelaunchEvents.contains(where: {$0.0 == eventClass && $0.1 == eventID}))) {
                    // event failed as target process has quit since previous event; recreate AppleEvent with new address and resend
                    self._targetDescriptor = nil
                    let event2 = NSAppleEventDescriptor(eventClass: eventClass, eventID: eventID, targetDescriptor: try self.targetDescriptor(),
                                                        returnID: AE4.autoGenerateReturnID, transactionID: AE4.anyTransactionID)
                    let count = event.numberOfItems
                    if count > 0 {
                        for i in 1...count {
                            event2.setParam(event.atIndex(i)!, forKeyword: event.keywordForDescriptor(at: i))
                        }
                    }
                    for key in [AE4.Attributes.subject, AE4.Attributes.considerations, AE4.Attributes.considsAndIgnores] {
                        event2.setAttribute(event.attributeDescriptor(forKeyword: key)!, forKeyword: key)
                    }
                    replyEvent = try self.send(event: event2, sendMode: sendMode, timeout: timeout)
                } else {
                    throw error
                }
            }
            repliedEvent = replyEvent
            if sendMode.contains(.waitForReply) {
                if
                    let errorNumber = replyEvent.paramDescriptor(forKeyword: AE4.Keywords.errorNumber)?.int32Value,
                    errorNumber != 0
                {
                    throw AutomationError(code: Int(errorNumber))
                } else if let resultDesc = replyEvent.paramDescriptor(forKeyword: AE4.Keywords.directObject) {
                    return try self.decode(resultDesc)
                }
                return .missingValue
            } else if sendMode.contains(.queueReply) { // get the return ID that will be used by the reply event so that client code's main loop can identify that reply event in its own event queue later on
                guard let returnIDDesc = event.attributeDescriptor(forKeyword: AE4.Attributes.returnID) else {
                    throw AutomationError(code: defaultErrorCode, message: "Can't get keyReturnIDAttr.")
                }
                return try self.decode(returnIDDesc)
            }
            return .missingValue
        } catch {
            let commandDescription = CommandDescription(
                eventClass: eventClass,
                eventID: eventID,
                parentSpecifier: targetSpecifier,
                directParameter: directParameter,
                keywordParameters: keywordParameters,
                requestedType: requestedType,
                waitReply: waitReply,
                withTimeout: timeout,
                considering: considering,
                ignoring: ignoring
            )
            throw CommandError(commandInfo: commandDescription, app: self, event: sentEvent, reply: repliedEvent, cause: error)
        }
    }
    
    private func send(event: NSAppleEventDescriptor, sendMode: SendOptions, timeout: TimeInterval) throws -> NSAppleEventDescriptor {
        do {
            return try event.sendEvent(options: sendMode, timeout: timeout) // throws NSError on AEM errors (but not app errors)
        } catch {
            // 'launch' events normally return 'not handled' errors, so just ignore those
            // TO DO: this is wrong; -1708 will be in reply event, not in AEM error; FIX
            if
                (error as NSError).code == -1708,
                event.attributeDescriptor(forKeyword: AE4.Attributes.eventClass)!.typeCodeValue == AE4.Events.AppleScript.eventClass,
                event.attributeDescriptor(forKeyword: AE4.Attributes.eventID)!.typeCodeValue == AE4.Events.AppleScript.IDs.launch
            {
                // not a full AppleEvent desc, but reply event's attributes aren't used so is equivalent to a reply event containing neither error nor result
                    return NSAppleEventDescriptor.record()
            } else {
                throw error
            }
        }
    }
    
}

// MARK: Target encoding
extension App {
    
    public func targetDescriptor() throws -> NSAppleEventDescriptor? {
        if _targetDescriptor == nil {
            _targetDescriptor = try target.descriptor(launchOptions)
        }
        return _targetDescriptor
    }
    
}

extension Specifier {
    
    /// Sends an AppleScript-compatible AppleEvent with this specifier as
    /// the target specifier, and with the (many available) given options.
    @discardableResult
    public func sendAppleEvent(
        _ eventClass: OSType,
        _ eventID: OSType,
        _ parameters: [OSType : Any] = [:],
        requestedType: Symbol? = nil,
        waitReply: Bool = true,
        sendOptions: SendOptions? = nil,
        timeout: TimeInterval? = nil,
        considering: Considerations? = nil,
        ignoring: Considerations? = nil
    ) throws -> AEValue
    {
        try app.sendAppleEvent(
            eventClass: eventClass,
            eventID: eventID,
            targetSpecifier: self,
            parameters: parameters,
            requestedType: requestedType,
            waitReply: waitReply,
            sendOptions: sendOptions,
            timeout: timeout,
            considering: considering,
            ignoring: ignoring
        )
    }
    
}
