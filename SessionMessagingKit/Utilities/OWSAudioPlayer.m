//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSAudioPlayer.h"
#import "TSAttachmentStream.h"
#import <AVFoundation/AVFoundation.h>
#import <SessionUtilitiesKit/SessionUtilitiesKit.h>
#import <SessionMessagingKit/SessionMessagingKit-Swift.h>
#import <MobileVLCKit/VLCMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// A no-op delegate implementation to be used when we don't need a delegate.
@interface OWSAudioPlayerDelegateStub : NSObject <OWSAudioPlayerDelegate>

@property (nonatomic) AudioPlaybackState audioPlaybackState;

@end

#pragma mark -

@implementation OWSAudioPlayerDelegateStub

- (void)setAudioProgress:(CGFloat)progress duration:(CGFloat)duration
{
    // Do nothing
}

- (void)showInvalidAudioFileAlert
{
    // Do nothing
}

- (void)audioPlayerDidFinishPlaying:(OWSAudioPlayer *)player successfully:(BOOL)flag
{
    // Do nothing
}

@end

#pragma mark -

@interface OWSAudioPlayer () <VLCMediaPlayerDelegate>

@property (nonatomic, readonly) NSURL *mediaUrl;
@property (nonatomic, nullable) VLCMediaPlayer *audioPlayer;
@property (nonatomic, nullable) NSTimer *audioPlayerPoller;
@property (nonatomic, readonly) OWSAudioActivity *audioActivity;

@end

#pragma mark -

@implementation OWSAudioPlayer

- (instancetype)initWithMediaUrl:(NSURL *)mediaUrl
                   audioBehavior:(OWSAudioBehavior)audioBehavior
{
    return [self initWithMediaUrl:mediaUrl audioBehavior:audioBehavior delegate:[OWSAudioPlayerDelegateStub new]];
}

- (instancetype)initWithMediaUrl:(NSURL *)mediaUrl
                        audioBehavior:(OWSAudioBehavior)audioBehavior
                        delegate:(id<OWSAudioPlayerDelegate>)delegate
{
    self = [super init];
    if (!self) {
        return self;
    }

    _mediaUrl = mediaUrl;
    _delegate = delegate;

    NSString *audioActivityDescription = [NSString stringWithFormat:@"%@ %@", @"OWSAudioPlayer", self.mediaUrl];
    _audioActivity = [[OWSAudioActivity alloc] initWithAudioDescription:audioActivityDescription behavior:audioBehavior];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:OWSApplicationDidEnterBackgroundNotification
                                               object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [DeviceSleepManager.sharedInstance removeBlockWithBlockObject:self];

    [self stop];
}

#pragma mark - Dependencies

- (OWSAudioSession *)audioSession
{
    return Environment.shared.audioSession;
}

#pragma mark

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self stop];
}

#pragma mark - Methods

- (BOOL)isPlaying
{
    return (self.delegate.audioPlaybackState == AudioPlaybackState_Playing);
}

- (void)play
{
    // get current audio activity
    [self playWithAudioActivity:self.audioActivity];
}

- (void)playWithAudioActivity:(OWSAudioActivity *)audioActivity
{
    [self.audioPlayerPoller invalidate];

    self.delegate.audioPlaybackState = AudioPlaybackState_Playing;

    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];

    if (!self.audioPlayer) {
        self.audioPlayer = [[VLCMediaPlayer alloc] initWithOptions:nil];
        self.audioPlayer.media = [VLCMedia mediaWithURL:self.mediaUrl];
        self.audioPlayer.delegate = self;
    }

    [self.audioPlayer play];
    [self.audioPlayerPoller invalidate];
    self.audioPlayerPoller = [NSTimer weakScheduledTimerWithTimeInterval:.05f
                                                                  target:self
                                                                selector:@selector(audioPlayerUpdated:)
                                                                userInfo:nil
                                                                 repeats:YES];

    // Prevent device from sleeping while playing audio.
    [DeviceSleepManager.sharedInstance addBlockWithBlockObject:self];
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    [self.audioPlayer setPosition:(float)currentTime/((float)self.audioPlayer.media.length.intValue/1000)];
}

- (float)getPlaybackRate
{
    return self.audioPlayer.rate;
}

- (void)setPlaybackRate:(float)rate
{
    [self.audioPlayer setRate:rate];
}

- (void)pause
{
    self.delegate.audioPlaybackState = AudioPlaybackState_Paused;
    [self.audioPlayer pause];
    [self.audioPlayerPoller invalidate];
    CGFloat progressSeconds = (CGFloat)self.audioPlayer.time.intValue/1000;
    CGFloat durationSeconds = (CGFloat)self.audioPlayer.media.length.intValue/1000;
    [self.delegate setAudioProgress:progressSeconds duration:durationSeconds];

    [self endAudioActivities];
    [DeviceSleepManager.sharedInstance removeBlockWithBlockObject:self];
}

- (void)stop
{
    self.delegate.audioPlaybackState = AudioPlaybackState_Stopped;
    [self.audioPlayer stop];
    [self.audioPlayerPoller invalidate];
    [self.delegate setAudioProgress:0 duration:0];

    [self endAudioActivities];
    [DeviceSleepManager.sharedInstance removeBlockWithBlockObject:self];
    if (self.isLooping) {
        [self play];
    }
}

- (void)endAudioActivities
{
    [self.audioSession endAudioActivity:self.audioActivity];
}

- (void)togglePlayState
{
    if (self.isPlaying) {
        [self pause];
    } else {
        [self playWithAudioActivity:self.audioActivity];
    }
}

#pragma mark - Events

- (void)audioPlayerUpdated:(NSTimer *)timer
{
    CGFloat progressSeconds = (CGFloat)self.audioPlayer.time.intValue/1000;
    CGFloat durationSeconds = (CGFloat)self.audioPlayer.media.length.intValue/1000;
    [self.delegate setAudioProgress:progressSeconds duration:durationSeconds];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stop];
    [self.delegate audioPlayerDidFinishPlaying:self successfully:flag];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = [self.audioPlayer state];
    if (currentState == VLCMediaPlayerStateEnded) {
        [self stop];
        [self.delegate audioPlayerDidFinishPlaying:self successfully:true];
    }
}

@end

NS_ASSUME_NONNULL_END
