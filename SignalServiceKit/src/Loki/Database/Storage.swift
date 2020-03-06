
/// Some important notes about YapDatabase:
///
/// • Connections are thread-safe.
/// • Executing a write transaction from within a write transaction is NOT allowed.
@objc(LKStorage)
public final class Storage : NSObject {

    private static var _writeTransaction: YapDatabaseReadWriteTransaction?
    private static var writeTransaction: YapDatabaseReadWriteTransaction? {
        get { isWriteQueue ? _writeTransaction : writeQueue.sync { _writeTransaction } }
        set {
            if isWriteQueue {
                _writeTransaction = newValue
            } else {
                writeQueue.sync { _writeTransaction = newValue }
            }
        }
    }

    private static var owsStorage: OWSPrimaryStorage { OWSPrimaryStorage.shared() }
    private static var writeConnection: YapDatabaseConnection { owsStorage.dbReadWriteConnection }
    /// Used internally by `dbReadWriteConnection` for `readWrite` operations.
    private static var connectionQueue: DispatchQueue { writeConnection.lk_getConnectionQueue() }
    /// Used internally by `dbReadWriteConnection` for `readWrite` operations.
    private static var writeQueue: DispatchQueue { owsStorage.lk_getWriteQueue() }
    private static var isWriteQueue: Bool { getQueueLabel() == getQueueLabel(writeQueue) }

    /// Some important points regarding reading from the database:
    ///
    /// • Background threads should use `OWSPrimaryStorage`'s `dbReadPool`, whereas the main thread should use `OWSPrimaryStorage`'s `uiDatabaseConnection` (see the `YapDatabaseConnectionPool` documentation for more information).
    /// • Multiple read transactions can safely be executed at the same time.
    @objc(readWithBlock:)
    public static func read(with block: @escaping (YapDatabaseReadTransaction) -> Void) {
        let isMainThread = Thread.current.isMainThread
        let connection = isMainThread ? owsStorage.uiDatabaseConnection : owsStorage.dbReadConnection
        connection.read(block)
    }

    /// Some important points regarding writing to the database:
    ///
    /// • There can only be a single write transaction per database at any one time, so all write transactions must use `OWSPrimaryStorage`'s `dbReadWriteConnection`.
    /// • Executing a write transaction from within a write transaction causes a deadlock and must be avoided.
    @objc(writeWithBlock:)
    public static func write(with block: @escaping (YapDatabaseReadWriteTransaction) -> Void) {
        if let writeTransaction = writeTransaction, writeConnection.pendingTransactionCount != 0 {
            block(writeTransaction)
        } else {
            writeConnection.readWrite { transaction in
                _writeTransaction = transaction
                block(transaction)
            }
            writeTransaction = nil
        }
    }

    private static func getQueueLabel(_ dispatchQueue: DispatchQueue? = nil) -> String? {
        let _label = __dispatch_queue_get_label(dispatchQueue)
        return String(cString: _label, encoding: .utf8)
    }
}
