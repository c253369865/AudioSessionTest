//
//  WTVideoPlayerView.m
//  WeToo
//
//  Created by Shingwa Six on 16/5/24.
//  Copyright © 2016年 LoveOrange. All rights reserved.
//

#import "WTVideoPlayerView.h"
#import "WTAudioManager.h"

#define WTLogDebug NSLog

@interface WTVideoPlayerView ()

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) id playbackTimeObserver;

@end

@implementation WTVideoPlayerView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    self.playerItem = nil;
//    [[WTAudioManager sharedInstance] deactiveSession:nil];
    
    NSLog(@"%@ be destory.", self);
}

- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem) {
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    }
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem) {
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    }
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem
{
//    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 12) queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0) usingBlock:^(CMTime time) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            NSTimeInterval currentTime = CMTimeGetSeconds(playerItem.currentTime);
//            weakSelf.trackingView.currentTime = currentTime;
        });
    }];
}

- (void)setPlaybackTimeObserver:(id)playbackTimeObserver
{
    if (_playbackTimeObserver) {
        [self.player removeTimeObserver:_playbackTimeObserver];
    }
    _playbackTimeObserver = playbackTimeObserver;
}

- (void)setUrl:(NSURL *)url
{
    if ([_url.absoluteString isEqualToString:url.absoluteString]) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        return;
    }
    _url = url;
    
    if (_url) {
        self.playerItem = [AVPlayerItem playerItemWithURL:url];
        [self.player play];
    } else {
        self.playerItem = nil;
        [self.player pause];
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem && _playerItem == playerItem) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        return;
    }
    self.playbackTimeObserver = nil;
    [self removeObserverFromPlayerItem:_playerItem];
    _playerItem = playerItem;
    [self addObserverToPlayerItem:_playerItem];
    if (_playerItem) {
        if (self.player) {
            [self.player replaceCurrentItemWithPlayerItem:_playerItem];
        } else {
            self.player = [AVPlayer playerWithPlayerItem:_playerItem];
        }
        [self.player seekToTime:kCMTimeZero];
    }
}

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.player.currentItem) {
        AVPlayerItem *playerItem = self.player.currentItem;
        if ([keyPath isEqualToString:@"status"]) {
            if ([playerItem status] == AVPlayerStatusReadyToPlay) {
                WTLogDebug(@"AVPlayerStatusReadyToPlay");
                [self.delegate videoPlayerViewDidReadyToPlayVideo:self];
                CGFloat totalDuration = CMTimeGetSeconds(playerItem.duration);
//                self.trackingView.totalDuration = totalDuration;
                WTLogDebug(@"Movie total duration:%f", totalDuration);
                [self monitoringPlayback:playerItem];
            } else if ([playerItem status] == AVPlayerStatusFailed) {
                WTLogDebug(@"AVPlayerStatusFailed");
                [self.delegate videoPlayerViewDidPlayVideoFail:self];
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            CGFloat totalDuration = CMTimeGetSeconds(playerItem.duration);
//            self.trackingView.totalDuration = totalDuration;
            WTLogDebug(@"loadedTimeRanges:%f", totalDuration);
        }
    }
    else if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSUInteger)currentMicroSecends
{
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * 1000;
    if (isnan(currentTime) ||
        currentTime <= 0) {
        currentTime = 1;
    }
    return currentTime;
}

- (void)playbackFinished:(NSNotification *)notification
{
    if (![self.delegate respondsToSelector:@selector(videoPlayerViewShouldReplay:)] ||
        [self.delegate videoPlayerViewShouldReplay:self]) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
    } else {
        [self.delegate videoPlayerViewDidFinishPlayback:self];
    }
}

#pragma mark - For Display Video

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[WTAudioManager sharedInstance] activeSessionPlay:^(WTAudioSessionCode code) {
//        
//    }];
}

- (void)applicationWillEnterForeground
{
    [self.player play];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)self.layer player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    switch (contentMode) {
        case UIViewContentModeScaleToFill:
        {
            [playerLayer setVideoGravity:AVLayerVideoGravityResize];
        }
            break;
        case UIViewContentModeScaleAspectFill:
        {
            [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        }
            break;
        case UIViewContentModeScaleAspectFit:
        {
            [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        }
            break;
        default:
        {
            NSLog(@"%@ doen't support this content mode.", self);
        }
            break;
    }
}

@end
