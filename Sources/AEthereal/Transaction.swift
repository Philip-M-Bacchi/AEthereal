//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

// In practice, there are few, if any, currently available apps that support transactions, but it's included for completeness.
extension App {
    
    public func withTransaction<T>(session: Any? = nil, do action: () throws -> (T)) throws -> T {
        _transactionLock.lock()
        defer {
            _transactionLock.unlock()
        }
        assert(self._transactionID == .any, "Transaction \(self._transactionID) already active.")
        
        self._transactionID = try beginTransaction()
        defer {
            self._transactionID = .any
        }
        
        do {
            let result = try action()
            try endTransaction()
            return result
        } catch {
            _ = try? abortTransaction()
            throw error
        }
    }
    
    private func beginTransaction() throws -> AETransactionID {
        try self.sendAppleEvent(eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.begin).int32Value
    }
    private func abortTransaction() throws {
        try self.sendAppleEvent(eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.terminated)
    }
    private func endTransaction() throws {
        try self.sendAppleEvent(eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.end)
    }
    
}
