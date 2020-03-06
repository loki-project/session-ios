#import "OWSPrimaryStorage+Threading.h"

@implementation OWSPrimaryStorage (Threading)

- (dispatch_queue_t)lk_getWriteQueue {
    return (dispatch_queue_t)[self.dbReadWriteConnection.database valueForKey:@"writeQueue"];
}

@end
