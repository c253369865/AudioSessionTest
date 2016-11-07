//
//  ZHAVPlayerView.h
//  AppDemo
//
//  Created by TerryChao on 16/7/19.
//  Copyright © 2016年 czh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer, AVPlayerItem;

@interface ZHAVPlayerView : UIView

@property (strong, nonatomic) AVPlayer *player;
//@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (assign, nonatomic) float volume;

- (void)playWithItem:(AVPlayerItem *)playerItem;

@end
