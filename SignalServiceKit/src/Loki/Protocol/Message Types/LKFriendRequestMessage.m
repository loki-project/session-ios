#import "LKFriendRequestMessage.h"
#import "OWSPrimaryStorage+Loki.h"
#import "NSDate+OWS.h"
#import "SignalRecipient.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

@implementation LKFriendRequestMessage

#pragma mark Initialization
- (SSKProtoContentBuilder *)prepareCustomContentBuilder:(SignalRecipient *)recipient {
    SSKProtoContentBuilder *contentBuilder = SSKProtoContent.builder;
    PreKeyBundle *preKeyBundle = [OWSPrimaryStorage.sharedManager generatePreKeyBundleForContact:recipient.recipientId];
    SSKProtoPrekeyBundleMessageBuilder *preKeyBundleMessageBuilder = [SSKProtoPrekeyBundleMessage builderFromPreKeyBundle:preKeyBundle];
    NSError *error;
    SSKProtoPrekeyBundleMessage *preKeyBundleMessage = [preKeyBundleMessageBuilder buildAndReturnError:&error];
    if (error || preKeyBundleMessage == nil) {
        OWSFailDebug(@"Failed to build pre key bundle message for: %@ due to error: %@.", recipient.recipientId, error);
        return nil;
    } else {
        [contentBuilder setPrekeyBundleMessage:preKeyBundleMessage];
    }
    return contentBuilder;
}

#pragma mark Building
- (nullable SSKProtoDataMessageBuilder *)dataMessageBuilder
{
    SSKProtoDataMessageBuilder *builder = super.dataMessageBuilder;
    if (builder == nil) { return nil; }
    [builder setFlags:self.flag];
    return builder;
}

#pragma mark Settings
- (uint)ttl {
    if (this.flag != 0) { return (uint)[LKTTLUtilities getTTLFor:LKMessageTypeEphemeral]; }
    return (uint)[LKTTLUtilities getTTLFor:LKMessageTypeFriendRequest];
}
- (BOOL)isSilent { return (this.flag != 0); }
- (BOOL)shouldSyncTranscript { return NO; }

@end
