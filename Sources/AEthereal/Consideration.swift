//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

public enum Consideration {
    case `case`
    case diacritic
    case whiteSpace
    case hyphens
    case expansion
    case punctuation
    case replies
    case numericStrings
}

public typealias Considerations = Set<Consideration>

private let defaultSendMode = SendOptions.defaultOptions.union(SendOptions.canSwitchLayer)
private let defaultIgnorances = encode(considering: defaultConsidering, ignoring: defaultIgnoring)


/******************************************************************************/

private let considerationsTable: [(Consideration, UInt32, UInt32)] = [
    // note: Swift mistranslates considering/ignoring mask constants as Int, not UInt32, so redefine them here
    (.case,           0x00000001, 0x00010000),
    (.diacritic,      0x00000002, 0x00020000),
    (.whiteSpace,     0x00000004, 0x00040000),
    (.hyphens,        0x00000008, 0x00080000),
    (.expansion,      0x00000010, 0x00100000),
    (.punctuation,    0x00000020, 0x00200000),
    (.numericStrings, 0x00000080, 0x00800000),
]

let defaultConsidering: Considerations = []
let defaultIgnoring: Considerations = [.case]
let defaultConsiderationsMask = considerationsMask(considering: defaultConsidering, ignoring: defaultIgnoring)

/// Encodes `considering` and `ignoring` as an `enumConsidsAndIgnores`
/// (`AE4.Attributes.considsAndIgnores`) bitmask.
func considerationsMask(considering: Considerations, ignoring: Considerations) -> UInt32 {
    var mask: UInt32 = 0
    for (consideration, consideringMask, ignoringMask) in considerationsTable {
        if considering.contains(consideration) {
            mask |= consideringMask
        } else if ignoring.contains(consideration) {
            mask |= ignoringMask
        }
    }
    return mask
}

/// Encodes `considering` and `ignoring` as an `enumConsidsAndIgnores`
/// (`AE4.Attributes.considsAndIgnores`) attribute descriptor.
func encode(considering: Considerations, ignoring: Considerations) -> NSAppleEventDescriptor {
    NSAppleEventDescriptor(uint32: considerationsMask(considering: considering, ignoring: ignoring))
}
