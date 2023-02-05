//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

let defaultErrorCode = 1

// base class for all SwiftAutomation-raised errors (not including NSErrors raised by underlying Cocoa APIs)
public class AutomationError: LocalizedError {
    
    /// NOTE: This member MUST be named _code.
    ///       There's apparently an obscure way to access an error code from
    ///       *any* Error object by accessing a member named _code.
    ///       This is hardly documented as far as I know, but it worked in
    ///       the original library and might actually be a good design here,
    ///       as it means we can expose the error code in a way consistent
    ///       with how NSErrors would.
    public var _code: Int
    public var message: String?
    public let cause: Error?
    
    public init(code: Int, message: String? = nil, cause: Error? = nil) {
        self._code = code
        self.message = message
        self.cause = cause
    }
    
    func description(_ previousCode: Int, separator: String = " ") -> String {
        let msg = self.message ?? descriptionForError[self._code]
        var string = "Error \(self._code)\(msg == nil ? "." : ": ")"
        if msg != nil { string += msg! }
        if let error = self.cause as? AutomationError {
            string += "\(separator)\(error.description(self._code))"
        } else if let error = self.cause {
            string += "\(separator)\(error)"
        }
        return string
    }
    
    public var errorDescription: String? {
        self.description(0)
    }
    
}

public class ConnectionError: AutomationError {
    
    public let target: AETarget
    
    public init(target: AETarget, message: String, cause: Error? = nil) {
        self.target = target
        super.init(code: defaultErrorCode, message: message, cause: cause)
    }
    
}

public class EncodeError: AutomationError {
    
    let object: Any
    
    public init(object: Any) {
        self.object = object
        super.init(code: errAECoercionFail, message: "Can't encode unsupported \(type(of: self.object)) value: \(self.object)")
    }
    
}

public class WrongType: AutomationError {
    
    let decoded: AEValue
    let type: Any.Type
    
    public init(_ decoded: AEValue, type: Any.Type) {
        self.decoded = decoded
        self.type = type
        super.init(code: errAECoercionFail, message: "\(decoded) is not a \(type)")
    }
    
}

public class SendFailure: AutomationError {
    
    let app: Application
    let event: AEDescriptor? // non-nil if event was built and sent
    let reply: AEDescriptor? // non-nil if reply event was received
    
    public init(app: Application, event: AEDescriptor? = nil, reply: AEDescriptor? = nil, cause: Error? = nil) {
        self.app = app
        self.event = event
        self.reply = reply
        var errorNumber = 1
        if let error = cause {
            errorNumber = error._code
        } else if let replyEvent = reply {
            if let appError = replyEvent.forKeyword(AE4.Keywords.errorNumber) {
                errorNumber = Int(appError.int32Value)
                // TO DO: [lazily] decode any other available error info
            }
        }
        super.init(code: errorNumber, message: "", cause: cause)
        // Doing after super.init = hacky workaround:
        self.message =
            reply?[AE4.Keywords.errorString]?.stringValue ??
            reply?[AE4.OSAErrorKeywords.briefMessage]?.stringValue ??
            descriptionForError[_code]
    }
    
    public var expectedType: AE4.AEType? {
        if
            let desc = self.reply?[AE4.OSAErrorKeywords.expectedType],
            let ae4 = try? AE4.AEType(from: AEDecoder(descriptor: desc))
        {
            return ae4
        } else {
            return nil
        }
    }
    
    public var offendingObject: AEValue? {
        if let desc = self.reply?[AE4.OSAErrorKeywords.offendingObject] {
            return try? AEValue(from: AEDecoder(descriptor: desc))
        } else {
            return nil
        }
    }
    
    public var partialResult: AEValue? {
        if let desc = self.reply?[AE4.OSAErrorKeywords.partialResult] {
            return try? AEValue(from: AEDecoder(descriptor: desc))
        } else {
            return nil
        }
    }
    
}
