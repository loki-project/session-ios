#import "TSOutgoingMessage.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EphemeralMessage)
@interface LKEphemeralMessage : TSOutgoingMessage

@property (nonatomic, readonly) NSUInteger flag;

- (instancetype)initInThread:(nullable TSThread *)thread;
- (instancetype)initInThread:(nullable TSThread *)thread flag:(NSUInteger)flag;

@end

NS_ASSUME_NONNULL_END
