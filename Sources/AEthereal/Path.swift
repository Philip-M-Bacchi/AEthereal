//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

public func HFSPath(fromFileURL url: URL) -> String {
    return AEDescriptor(fileURL: url).coerce(toDescriptorType: typeUnicodeText)!.stringValue!
}

public func fileURL(fromHFSPath path: String) -> URL {
    return AEDescriptor(string: path).coerce(toDescriptorType: typeFileURL)!.fileURLValue!
}
