#import "LKSyncOpenGroupsMessage.h"
#import "OWSPrimaryStorage.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation LKSyncOpenGroupsMessage

- (instancetype)init
{
    return [super init];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (nullable SSKProtoSyncMessageBuilder *)syncMessageBuilder
{
    NSError *error;
    NSMutableArray<SSKProtoSyncMessageOpenGroups *> *openGroupMessageProtos = @[].mutableCopy;
    __block NSDictionary<NSString *, LKPublicChat *> *openGroups;
    [OWSPrimaryStorage.sharedManager.dbReadConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        openGroups = [LKDatabaseUtilities getAllPublicChats:transaction];
    }];
    for (LKPublicChat *openGroup in openGroups.allValues) {
        SSKProtoSyncMessageOpenGroupsBuilder *openGroupMessageBuilder = [SSKProtoSyncMessageOpenGroups builder];
        [openGroupMessageBuilder setUrl:openGroup.server];
        [openGroupMessageBuilder setChannel:openGroup.channel];
        SSKProtoSyncMessageOpenGroups *_Nullable openGroupMessageProto = [openGroupMessageBuilder buildAndReturnError:&error];
        if (error || !openGroupMessageProto) {
            OWSFailDebug(@"Couldn't build protobuf due to error: %@.", error);
            return nil;
        }
        [openGroupMessageProtos addObject:openGroupMessageProto];
    }
    SSKProtoSyncMessageBuilder *syncMessageBuilder = [SSKProtoSyncMessage builder];
    [syncMessageBuilder setOpenGroups:openGroupMessageProtos];
    return syncMessageBuilder;
}

@end

NS_ASSUME_NONNULL_END
