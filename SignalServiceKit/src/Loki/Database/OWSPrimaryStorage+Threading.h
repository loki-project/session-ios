#import "OWSPrimaryStorage.h"

@interface OWSPrimaryStorage (Threading)

- (dispatch_queue_t)lk_getWriteQueue NS_SWIFT_NAME(lk_getWriteQueue());

@end
