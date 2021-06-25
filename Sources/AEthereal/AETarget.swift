//  Originally written by hhas.
//  See README.md for licensing information.

import AppKit

// AE errors indicating process unavailable // TO DO: finalize
private let processNotFoundErrorNumbers: Set<Int> = [procNotFound, connectionInvalid, localOnlyErr]

private let launchEventSucceededErrorNumbers: Set<Int> = [Int(noErr), errAEEventNotHandled]

private let untargetedLaunchEvent = AEDescriptor(eventClass: AE4.Events.AppleScript.eventClass, eventID: AE4.Events.AppleScript.IDs.launch, target: .appRoot)

/// A target that can receive AppleEvents.
public enum AETarget: CustomStringConvertible {
    
    case current
    case name(String) // application's name (.app suffix is optional) or full path
    case url(URL) // "file" or "eppc" URL
    case bundleIdentifier(String)
    case processIdentifier(pid_t)
    case descriptor(AEDescriptor) // AEAddressDesc
    case none // used in untargeted App instances; sendAppleEvent() will raise ConnectionError if called
    
    public var description: String {
        switch self {
        case .current:
            return "current app"
        case .name(let name):
            return "app named \(name)"
        case .url(let url):
            return "app at \(url.absoluteString)"
        case .bundleIdentifier(let identifier):
            return "app id \(identifier)"
        case .processIdentifier(let pid):
            return "app with pid \(pid)"
        case .descriptor(let descriptor):
            return "app by descriptor \(descriptor)"
        case .none:
            return "invalid app"
        }
    }
    
    // support functions
    
    private func localRunningApplication(url: URL) throws -> NSRunningApplication? { // TO DO: rename processForLocalApplication
        guard let bundleID = Bundle(url: url)?.bundleIdentifier else {
            throw ConnectionError(target: self, message: "Application not found: \(url)")
        }
        let foundProcesses = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if foundProcesses.count == 1 {
            return foundProcesses[0]
        } else if foundProcesses.count > 1 {
            for process in foundProcesses {
                if process.bundleURL == url { // TO DO: FIX: need to check for FS equality
                    /*
                     function idForFileURL(url) {
                         const fileIDRef = objc.alloc(objc.NSData, objc.NIL).ref();
                         if (!url('getResourceValue', fileIDRef, 'forKey', objc.NSURLFileResourceIdentifierKey, 'error', null)) {
                             throw new Error(`Can't get NSURLFileResourceIdentifierKey for ${url}`);
                         }
                         return fileIDRef.deref();
                     }
                     */
                    return process
                }
            }
        }
        return nil
    }
    
    private func sendLaunchEvent(processDescriptor: AEDescriptor) -> Int {
        do {
            let event = AEDescriptor(eventClass: AE4.Events.AppleScript.eventClass, eventID: AE4.Events.AppleScript.IDs.launch, target: processDescriptor)
            let reply = try event.sendEvent(options: .waitForReply, timeout: 30)
            return Int(reply[keyErrorNumber]?.int32Value ?? 0) // application error (errAEEventNotHandled is normal)
        } catch {
            return (error as Error)._code // AEM error
        }
    }
    
    private func processDescriptorForLocalApplication(url: URL, launchOptions: LaunchOptions) throws -> AEDescriptor {
        // get a typeKernelProcessID-based AEAddressDesc for the target app, finding and launch it first if not already running;
        // if app can't be found/launched, throws a ConnectionError/NSError instead
        let runningProcess = try (self.localRunningApplication(url: url) ??
            NSWorkspace.shared.launchApplication(at: url, options: launchOptions, configuration: [:]))
        return AEDescriptor(processIdentifier: runningProcess.processIdentifier)
    }
    
    private func isRunning(processDescriptor: AEDescriptor) -> Bool {
        // check if process is running by sending it a 'noop' event; used by isRunning property
        // this assumes app is running unless it receives an AEM error that explicitly indicates it isn't (a bit crude, but when the only identifying information for the target process is an arbitrary AEAddressDesc there isn't really a better way to check if it's running other than send it an event and see what happens)
        return !processNotFoundErrorNumbers.contains(self.sendLaunchEvent(processDescriptor: processDescriptor))
    }
    
    private func bundleIdentifier(processDescriptor: AEDescriptor) -> String? {
        let specifier = RootSpecifier.application.byProperty(AE4.AEEnum(rawValue: AE4.Properties.id))
        guard
            let reply = try? App(target: .descriptor(processDescriptor)).sendAppleEvent(eventClass: AE4.Suites.coreSuite, eventID: AE4.AESymbols.getData, targetQuery: .objectSpecifier(specifier)),
            let id = try? String(from: AEDecoder(descriptor: reply))
        else {
            return nil
        }
        return id
    }
    
    /// Whether this target can be automatically relaunched.
    /// Only certain targeting modes permit this.
    public var isRelaunchable: Bool {
        switch self {
        case .name, .bundleIdentifier:
            return true
        case .url(let url):
            return url.isFileURL
        default:
            return false
        }
    }
    
    /// Whether this target is running, and thus possibly able to receive
    /// AppleEvents.
    public var isRunning: Bool {
        switch self {
        case .current:
            return true
        case .name(let name): // application's name (.app suffix is optional) or full path
            if let url = fileURLForLocalApplication(name) {
                return (((try? self.localRunningApplication(url: url)) as NSRunningApplication??)) != nil
            }
        case .url(let url): // "file" or "eppc" URL
            if url.isFileURL {
                return (((try? self.localRunningApplication(url: url)) as NSRunningApplication??)) != nil
            } else if url.scheme == "eppc" {
                return self.isRunning(processDescriptor: AEDescriptor(applicationURL: url))
            }
        case .bundleIdentifier(let bundleID):
            return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 0
        case .processIdentifier(let pid):
            return NSRunningApplication(processIdentifier: pid) != nil
        case .descriptor(let addressDesc):
            return self.isRunning(processDescriptor: addressDesc)
        case .none: // used in untargeted App instances; sendAppleEvent() will raise ConnectionError if called
            break
        }
        return false
    }
    
    /// Bundle ID of this target, if available.
    public var bundleIdentifier: String? {
        switch self {
        case .current:
            return NSRunningApplication.current.bundleIdentifier
        case .name(let name):
            return fileURLForLocalApplication(name).flatMap { Bundle(url: $0) }?.bundleIdentifier
        case .url(let url):
            if url.isFileURL {
                return Bundle(url: url)?.bundleIdentifier
            } else if url.scheme == "eppc" {
                return bundleIdentifier(processDescriptor: AEDescriptor(applicationURL: url))
            } else {
                return nil
            }
        case .bundleIdentifier(let bundleID):
            return bundleID
        case .processIdentifier(let pid):
            return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        case .descriptor(let addressDesc):
            return bundleIdentifier(processDescriptor: addressDesc)
        case .none:
            return nil
        }
    }
    
    /// Launches this target. Equivalent to AppleScript's `launch` command.
    /// Handles the edge case of Script Editor applets that aren't saved as
    /// "stay open", which only handle the first event they receive
    /// and then quit.
    public func launch() throws { // called by RootSpecifier.launch()
        if self.isRunning {
            let errorNumber = self.sendLaunchEvent(processDescriptor: try self.descriptor()!)
            if !launchEventSucceededErrorNumbers.contains(errorNumber) {
                throw AutomationError(code: errorNumber, message: "Can't launch application.")
            }
        } else {
            switch self {
            case .name(let name):
                if let url = fileURLForLocalApplication(name) {
                    try self.launch(url: url)
                    return
                }
            case .url(let url) where url.isFileURL:
                try self.launch(url: url)
                return
            case .bundleIdentifier(let bundleID):
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                    try self.launch(url: url)
                    return
                }
            default:
                ()
            } // fall through on failure
            throw ConnectionError(target: self, message: "Can't launch application.")
        }
    }
    
    private func launch(url: URL) throws {
        try NSWorkspace.shared.launchApplication(at: url, options: [.withoutActivation], configuration: [.appleEvent: untargetedLaunchEvent])
    }
    
    /// Makes an `AEDescriptor` for this target, if possible.
    ///
    /// If the target is relaunchable and not currently running,
    /// it will be launched.
    /// If the target is `.current`, the result will be `.currentProcess()`.
    /// If the target is local to this machine, the result will refer to a PID.
    public func descriptor(_ launchOptions: LaunchOptions = launchOptions) throws -> AEDescriptor? {
        switch self {
        case .current:
            return AEDescriptor.currentProcess()
        case .name(let name): // app name or full path
            guard let url = fileURLForLocalApplication(name) else {
                throw ConnectionError(target: self, message: "Application not found: \(name)")
            }
            return try self.processDescriptorForLocalApplication(url: url, launchOptions: launchOptions)
        case .url(let url): // file/eppc URL
            if url.isFileURL {
                return try self.processDescriptorForLocalApplication(url: url, launchOptions: launchOptions)
            } else if url.scheme == "eppc" {
                return AEDescriptor(applicationURL: url)
            } else {
                throw ConnectionError(target: self, message: "Invalid URL scheme (not file/eppc): \(url)")
            }
        case .bundleIdentifier(let bundleID):
            do {
                let runningProcess = try NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID,
                                                                                options: launchOptions, configuration: [:])
                return AEDescriptor(processIdentifier: runningProcess.processIdentifier)
            } catch {
                throw ConnectionError(target: self, message: "Can't find/launch application: \(bundleID)", cause: error)
            }
        case .processIdentifier(let pid):
            return AEDescriptor(processIdentifier: pid)
        case .descriptor(let desc):
            return desc
        case .none:
            throw ConnectionError(target: .none, message: "Untargeted specifiers can't send Apple events.")
        }
    }
}

/// Retrieves a file URL to the app named `name` on this machine.
///
/// `name` may be either an absolute path ending in `.app`,
/// or the name of an app registered with Launch Services (with optional
/// `.app` extension).
public func fileURLForLocalApplication(_ name: String) -> URL? {
    if name.hasPrefix("/") {
        return URL(fileURLWithPath: name)
    } else {
        guard let path = NSWorkspace.shared.fullPath(forApplication: name) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}
