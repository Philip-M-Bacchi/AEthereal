//  Originally written by hhas.
//  See README.md for licensing information.

import Foundation

extension RootSpecifier {
    
    public func withTransaction<T>(session: Any? = nil, do action: () throws -> T) throws -> T {
        try app.withTransaction(session: session, do: action)
    }
    
}

// In practice, there are few, if any, currently available apps that support transactions, but it's included for completeness.
extension App {
    
    public func withTransaction<T>(session: Any? = nil, do action: () throws -> (T)) throws -> T {
        _transactionLock.lock()
        defer {
            _transactionLock.unlock()
        }
        assert(self._transactionID == AE4.anyTransactionID, "Transaction \(self._transactionID) already active.")
        
        self._transactionID = try beginTransaction()
        defer {
            self._transactionID = AE4.anyTransactionID
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
    
    private func beginTransaction(session: Any? = nil) throws -> AETransactionID {
        try self.sendAppleEvent(eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.begin, targetSpecifier: App.generic.application, directParameter: session as Any).int32()
    }
    private func abortTransaction() throws {
        try self.sendAppleEvent(eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.terminated, targetSpecifier: App.generic.application)
    }
    private func endTransaction() throws {
        try self.sendAppleEvent(eventClass: AE4.Events.Transactions.eventClass, eventID: AE4.Events.Transactions.IDs.end, targetSpecifier: App.generic.application)
    }
    
}
