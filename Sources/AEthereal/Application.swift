//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

public final class Application {
    
    public static var generic = Application()
    
    public init(target: AETarget = .none) {
        self.target = target
    }
    
    public let target: AETarget
    
    var _targetDescriptor: AEDescriptor? = nil
    
    var _transactionID: AETransactionID = .any
    var _transactionLock = NSLock()
    
}
