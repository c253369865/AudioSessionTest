//
//  ZHAVPlayerView.m
//  AppDemo
//
//  Created by TerryChao on 16/7/19.
//  Copyright © 2016年 czh. All rights reserved.
//

#import "ZHAVPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation ZHAVPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [((AVPlayerLayer *)[self layer]) player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [((AVPlayerLayer *)[self layer]) setPlayer:player];
}


- (void)playWithItem:(AVPlayerItem *)playerItem
{
    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    else {
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
    }
    [self.player play];
}

- (void)setVolume:(float)volume
{
    _volume = volume;
    if (self.player) {
        self.player.volume = _volume;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
