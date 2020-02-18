#import "YapDatabaseConnection+Threading.h"

@implementation YapDatabaseConnection (Threading)

- (dispatch_queue_t)lk_getConnectionQueue {
    return (dispatch_queue_t)[self valueForKey:@"connectionQueue"];
}

@end
