#import "LKEphemeralMessage.h"
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

@implementation LKEphemeralMessage

#pragma mark Initialization
- (instancetype)initInThread:(nullable TSThread *)thread {
    return [super initOutgoingMessageWithTimestamp:NSDate.ows_millisecondTimeStamp inThread:thread messageBody:@"" attachmentIds:[NSMutableArray<NSString *> new]
        expiresInSeconds:0 expireStartedAt:0 isVoiceMessage:NO groupMetaMessage:TSGroupMetaMessageUnspecified quotedMessage:nil contactShare:nil linkPreview:nil];
}

- (instancetype)initInThread:(nullable TSThread *)thread flag:(NSUInteger)flag {
    self = [super initOutgoingMessageWithTimestamp:NSDate.ows_millisecondTimeStamp inThread:thread messageBody:@"" attachmentIds:[NSMutableArray<NSString *> new]
        expiresInSeconds:0 expireStartedAt:0 isVoiceMessage:NO groupMetaMessage:TSGroupMetaMessageUnspecified quotedMessage:nil contactShare:nil linkPreview:nil];
    if (self) {
        _flag = flag;
    }
    return self;
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
- (BOOL)shouldSyncTranscript { return NO; }
- (BOOL)shouldBeSaved { return NO; }
- (uint)ttl { return (uint)[LKTTLUtilities getTTLFor:LKMessageTypeEphemeral]; }

@end
