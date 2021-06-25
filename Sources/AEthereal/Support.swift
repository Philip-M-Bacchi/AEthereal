//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation
import AppKit

/******************************************************************************/
// KLUDGE: NSWorkspace provides a good method for launching apps by file URL, and a crap one for launching by bundle ID - unfortunately, only the latter can be used in sandboxed apps. This extension adds a launchApplication(withBundleIdentifier:options:configuration:)throws->NSRunningApplication method that has a good API and the least compromised behavior, insulating AETarget code from the crappiness that hides within. If/when Apple adds a real, robust version of this method to NSWorkspace <rdar://29159280>, this extension can (and should) go away.

extension NSWorkspace { 
    
    // caution: the configuration parameter is ignored in sandboxed apps; this is unavoidable
    @objc func launchApplication(withBundleIdentifier bundleID: String, options: NSWorkspace.LaunchOptions = [],
                           configuration: [NSWorkspace.LaunchConfigurationKey : Any]) throws -> NSRunningApplication {
        // if one or more processes with the given bundle ID is already running, return the first one found
        let foundProcesses = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if foundProcesses.count > 0 {
            return foundProcesses[0]
        }
        // first try to get the app's file URL, as this lets us use the better launchApplication(at:options:configuration:) method…
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            do {
                return try NSWorkspace.shared.launchApplication(at: url, options: options, configuration: configuration)
            } catch {} // for now, we're not sure if urlForApplication(withBundleIdentifier:) will always return nil if blocked by sandbox; if it returns garbage URL instead then hopefully that'll cause launchApplication(at:...) to throw
        }
        // …else fall back to the inferior launchApplication(withBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifier:)
        var options = options
        options.remove(NSWorkspace.LaunchOptions.async)
        if NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, options: options,
                                                  additionalEventParamDescriptor: nil, launchIdentifier: nil) {
            // TO DO: confirm that launchApplication() never returns before process is available (otherwise the following will need to be in a loop that blocks until it is available or the loop times out)
            let foundProcesses = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if foundProcesses.count > 0 {
                return foundProcesses[0]
            }
        }
        throw NSError(domain: NSCocoaErrorDomain, code: 1, userInfo:
                      [NSLocalizedDescriptionKey: "Can't find/launch application \(bundleID.debugDescription)"]) // TO DO: what error to report here, since launchApplication(withBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifier:) doesn't provide any error info itself?
    }
}

/******************************************************************************/
// logging

struct StderrStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}
var errStream = StderrStream()

/******************************************************************************/
// convert between 4-character strings and OSTypes (use these instead of calling UTGetOSTypeFromString/UTCopyStringFromOSType directly)

extension FourCharCode {
    
    public init(fourByteString string: String) throws {
        // convert four-character string containing MacOSRoman characters to AE4
        // (this is safer than using UTGetOSTypeFromString, which silently fails if string is malformed)
        guard let data = string.data(using: .macOSRoman) else {
            throw AutomationError(code: 1, message: "Invalid four-char code (bad encoding): \(string.debugDescription)")
        }
        guard data.count == 4 else {
            throw AutomationError(code: 1, message: "Invalid four-char code (wrong length): \(string.debugDescription)")
        }
        let reinterpreted = data.withUnsafeBytes { $0.bindMemory(to: FourCharCode.self).first! }
        self.init(reinterpreted.bigEndian)
    }
    
}

extension String {
    
    public init(ae4Code: AE4) {
        // convert an AE4 to four-character string containing MacOSRoman characters
        self.init(UTCreateStringForOSType(ae4Code).takeRetainedValue() as String)
    }
    
    public var ae4Code: AE4? {
        // TODO: This function doesn't have any error reporting.
        UTGetOSTypeFromString(self as CFString)
    }
    
}

/*
func formatAE4Code(_ code: AE4) -> String {
    var n = CFSwapInt32HostToBig(code)
    var result = ""
    for _ in 1...4 {
        let c = n % 256
        result += String(format: (c == 0x21 || 0x23 <= c && c <= 0x7e) ? "%c" : "\\0x%02X", c)
        n >>= 8
    }
    return "\"\(result)\""
}
 */


public func eightCharCode(_ eventClass: AE4, _ eventID: AE4) -> UInt64 {
    return UInt64(eventClass) << 32 | UInt64(eventID)
}
