
@objc(LKClosedGroupFailedDecryptionJobQueue)
public final class ClosedGroupFailedDecryptionJobQueue : NSObject, JobQueue {
    public let requiresInternet: Bool = false
    public var runningOperations: [ClosedGroupFailedDecryptionOperation] = []
    public var isSetup: Bool = false

    public static let jobRecordLabel: String = "ClosedGroupFailedDecryptionJob"
    public static let maxRetries: UInt = 24

    public var jobRecordLabel: String { ClosedGroupFailedDecryptionJobQueue.jobRecordLabel }

    public typealias DurableOperationType = ClosedGroupFailedDecryptionOperation

    private let defaultQueue: OperationQueue = {
        let result = OperationQueue()
        result.name = "ClosedGroupFailedDecryptionJobQueue.defaultQueue"
        result.maxConcurrentOperationCount = 4
        result.qualityOfService = .userInitiated
        return result
    }()

    // MARK: Initialization
    @objc
    public override init() {
        super.init()
        AppReadiness.runNowOrWhenAppWillBecomeReady {
            self.setup()
        }
    }

    @objc
    public func setup() {
        defaultSetup()
    }

    @objc(addEnvelopeData:transaction:)
    public func add(_ envelopeData: Data, transaction: YapDatabaseReadWriteTransaction) {
        print("[Test] add(_:transaction:)")
        assert(AppReadiness.isAppReady() || CurrentAppContext().isRunningTests)
        let jobRecord: ClosedGroupFailedDecryptionJobRecord
        do {
            jobRecord = try ClosedGroupFailedDecryptionJobRecord(envelopeData: envelopeData, label: jobRecordLabel)
        } catch {
            return owsFailDebug("Couldn't build job due to error: \(error)")
        }
        add(jobRecord: jobRecord, transaction: transaction)
    }

    public func didMarkAsReady(oldJobRecord: ClosedGroupFailedDecryptionJobRecord, transaction: YapDatabaseReadWriteTransaction) {
        print("[Test] didMarkAsReady(oldJobRecord:transaction:)")
        // Do nothing
    }

    public func buildOperation(jobRecord: ClosedGroupFailedDecryptionJobRecord, transaction: YapDatabaseReadTransaction) throws -> ClosedGroupFailedDecryptionOperation {
        return ClosedGroupFailedDecryptionOperation(envelopeData: jobRecord.envelopeData, jobRecord: jobRecord)
    }

    public func operationQueue(jobRecord: ClosedGroupFailedDecryptionJobRecord) -> OperationQueue {
        return defaultQueue
    }
}

public final class ClosedGroupFailedDecryptionOperation : OWSOperation, DurableOperation {
    public let envelopeData: Data
    public let jobRecord: ClosedGroupFailedDecryptionJobRecord
    weak public var durableOperationDelegate: ClosedGroupFailedDecryptionJobQueue?

    public var operation: OWSOperation { return self }

    struct DecryptionFailedError : Error { }

    init(envelopeData: Data, jobRecord: ClosedGroupFailedDecryptionJobRecord) {
        self.envelopeData = envelopeData
        self.jobRecord = jobRecord
        super.init()
    }

    override public func run() {
        print("[Test] run")
        // FIXME: This is a lot like what happens in OWSMessageReceiver, but with a few assumptions baked in that * should * be valid
        // assuming this is only used to handle SSK ratcheting errors. In the future it'd be nice to look into merging this with the code
        // in OWSMessageReceiver to reduce code duplication.
        let envelope: SSKProtoEnvelope
        do {
            envelope = try SSKProtoEnvelope.parseData(envelopeData)
        } catch {
            print("[Test] Couldn't parse envelope: \(error)")
            return reportError(error)
        }
        let envelopeData = self.envelopeData
        SSKEnvironment.shared.messageReceiver.serialQueue().async { [weak self] in
            SSKEnvironment.shared.messageDecrypter.decryptEnvelope(envelope, envelopeData: envelopeData, successBlock: { result, _ in
                do {
                    try Storage.writeSync { transaction in
                        SSKEnvironment.shared.batchMessageProcessor.enqueueEnvelopeData(result.envelopeData, plaintextData: result.plaintextData, wasReceivedByUD: true, transaction: transaction)
                        self?.reportSuccess()
                    }
                } catch {
                    self?.reportError(error)
                }
            }, failureBlock: {
                self?.reportError(DecryptionFailedError()) // Essentially just a dummy error
            })
        }
    }

    override public func didSucceed() {
        print("[Test] didSucceed")
        try! Storage.writeSync { [weak self] transaction in
            guard let self = self else { return }
            self.durableOperationDelegate?.durableOperationDidSucceed(self, transaction: transaction)
        }
    }

    override public func didReportError(_ error: Error) {
        print("[Test] didReportError(error: \(error))")
        try! Storage.writeSync { [weak self] transaction in
            guard let self = self else { return }
            self.durableOperationDelegate?.durableOperation(self, didReportError: error, transaction: transaction)
        }
    }

    override public func didFail(error: Error) {
        print("[Test] didFail(error: \(error))")
        try! Storage.writeSync { [weak self] transaction in
            guard let self = self else { return }
            self.durableOperationDelegate?.durableOperation(self, didFailWithError: error, transaction: transaction)
        }
    }

    override public func retryInterval() -> TimeInterval {
        print("[Test] Retrying... (jobRecord.failureCount: \(jobRecord.failureCount))")
        // Arbitrary backoff factor...
        // With backOffFactor of 1.9
        // try  1 delay:  0.00s
        // try  2 delay:  0.19s
        // ...
        // try  5 delay:  1.30s
        // ...
        // try 11 delay: 61.31s
        let backoffFactor = 1.9
        let maxBackoff = 15 * kMinuteInterval
        let seconds = 0.1 * min(maxBackoff, pow(backoffFactor, Double(self.jobRecord.failureCount)))
        return seconds
    }
}

public final class ClosedGroupFailedDecryptionJobRecord : SSKJobRecord {
    @objc public var envelopeData: Data!

    init(envelopeData: Data, label: String) {
        print("[Test] ClosedGroupFailedDecryptionJobRecord.init(envelopeData: \(envelopeData), label: \(label))")
        self.envelopeData = envelopeData
        super.init(label: label)
    }

    public required init?(coder: NSCoder) {
        print("[Test] ClosedGroupFailedDecryptionJobRecord.init(coder: ...)")
        super.init(coder: coder)
        print("[Test] ClosedGroupFailedDecryptionJobRecord.init(coder: ...) → envelopeData: \(envelopeData)")
    }

    public required init(dictionary: [String:Any]!) throws {
        print("[Test] ClosedGroupFailedDecryptionJobRecord.init(dictionary: \(dictionary)")
        try super.init(dictionary: dictionary)
        print("[Test] ClosedGroupFailedDecryptionJobRecord.init(dictionary: \(dictionary) → envelopeData: \(envelopeData)")
    }
}
