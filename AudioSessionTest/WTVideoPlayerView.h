//
//  WTVideoPlayerView.h
//  WeToo
//
//  Created by Shingwa Six on 16/5/24.
//  Copyright © 2016年 LoveOrange. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "WTVideoTrackingView.h"
@import AVFoundation;

@protocol WTVideoPlayerViewDelegate;
@interface WTVideoPlayerView : UIView

//@property (nonatomic, weak) IBOutlet WTVideoTrackingView *trackingView;
@property (nonatomic, weak) id<WTVideoPlayerViewDelegate> delegate;

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) AVPlayer *player;

- (void)play;
- (void)pause;

- (NSUInteger)currentMicroSecends;

@end


@protocol WTVideoPlayerViewDelegate <NSObject>

@optional

- (void)videoPlayerViewDidReadyToPlayVideo:(WTVideoPlayerView *)playerView;
- (void)videoPlayerViewDidPlayVideoFail:(WTVideoPlayerView *)playerView;
- (BOOL)videoPlayerViewShouldReplay:(WTVideoPlayerView *)playerView;
- (void)videoPlayerViewDidFinishPlayback:(WTVideoPlayerView *)playerView;

@end
