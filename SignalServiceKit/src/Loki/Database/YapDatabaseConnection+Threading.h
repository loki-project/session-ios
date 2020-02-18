#import <YapDatabase/YapDatabaseConnection.h>

@interface YapDatabaseConnection (Threading)

- (dispatch_queue_t)lk_getConnectionQueue NS_SWIFT_NAME(lk_getConnectionQueue());

@end
