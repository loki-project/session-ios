/// Loki: Refer to Docs/SessionReset.md for explanations

#import "SessionCipher.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kNSNotificationName_SessionAdopted;
extern NSString *const kNSNotificationKey_ContactPubKey;

@interface SessionCipher (Loki)

- (NSData *)throws_lokiDecrypt:(id<CipherMessage>)whisperMessage protocolContext:(nullable id)protocolContext NS_SWIFT_UNAVAILABLE("throws objc exceptions");

@end

NS_ASSUME_NONNULL_END
