//
//  WTAudioSession.h
//  WeToo
//
//  Created by TerryChao on 2016/10/18.
//  Copyright © 2016年 LoveOrange. All rights reserved.
//

/*
 想法: APP 启动 请求麦克风权限;初始 AVAudioSession, 在需要的地方激活 AVAudioSession, 用完释放 AVAudioSession,并通知其他应用继续本身的音频活动;
 Category : AVAudioSessionCategoryPlayAndRecord -- 既需要播放声音又需要录音
 需要考虑: 耳机,蓝牙,后台
 */

/*
 
 1. 不激活session无法录音;但可以播放音频,但是播放时音乐会停止;
 
 流程:
 1. 打开APP,记录之前的session设置;
 
 录音
 1. 设置录音类型,激活会话(假如已经激活,则跳过)
 2. 开始录音,结束录音
 
 播放
 1. 设置录音类型,激活会话
 2. 播放
 3. 播放完或者手动停止播放;关闭会话,并激活其他APP
 
 
 状态:
 录音
 正常: 没激活 - 激活 - 录音 - 释放
 
 假如没有其他 APP 在使用 音频, 那么就不释放了.
 
 没有其它 APP 在使用音频
 1. 录音, 都不会录制到其他 APP 的声音
  开始录音 : 使用 AVAudioSessionCategoryPlayAndRecord,  不使用 Option, 激活 session;
  录音结束 : 判断是否有其他类型的 APP 在使用, 没有就 不释放 session;
 
 2. 播放
 开始播放 : 使用 AVAudioSessionCategoryPlayAndRecord,  Option : AVAudioSessionCategoryOptionDefaultToSpeaker, 激活 session;
 播放结束 : 判断是否有其他类型的 APP 在使用, 没有就 不释放 session;
 
 其它 APP 在使用音频
 1. 录音, 使用 AVAudioSessionCategoryPlayAndRecord,  不使用 Option, 都不会录制到其他 APP 的声音;
  开始录音 : 使用 AVAudioSessionCategoryPlayAndRecord,  不使用 Option, 激活 session;
    如果录制不带其他APP的音频 : 使用 AVAudioSessionCategoryPlayAndRecord, Option : AVAudioSessionCategoryOptionDefaultToSpeaker
    如果录制带其他APP的音频 :  使用 AVAudioSessionCategoryPlayAndRecord, Option : AVAudioSessionCategoryOptionMixWithOthers
  录音结束 : 释放 session, 激活其他APP的音频;
 
问题:
 1. 一个困扰了很久的问题:释放时说 IOBusy, 很大的原因是 播放完后后马上调用释放,这时候的确是 IOBusy, 暂时采用延时0.1s在释放;
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, WTAudioSessionCode) {
    WTAudioSessionCodeSueecss = 0,
    WTAudioSessionCodeFail = -1,
    WTAudioSessionCodeSwitching = -2,
};

typedef void (^CommonVoidBlock)();
typedef void (^FinishBlock)(WTAudioSessionCode code);

@protocol WTAudioManagerDelegate <NSObject>

- (void)startRecord;
- (void)stopRecord:(NSString *)audioPath duration:(NSTimeInterval)realRecordDuration;
- (void)willCancelRecord;

@end


typedef NS_ENUM(NSUInteger, WTAudioSessionStatus) {
    WTAudioSessionStatusNone,
    WTAudioSessionStatusRecord,
    WTAudioSessionStatusPlayback,
};

typedef NS_ENUM(NSUInteger, WTAudioCategory) {
    WTAudioCategoryNil,
    WTAudioCategoryRecordWithoutMusic,
    WTAudioCategoryRecordWithMusic,
    WTAudioCategoryPlayWithoutMusic,
    WTAudioCategoryPlayWithMusic,
};

@interface WTAudioManager : NSObject

@property (nonatomic, weak) id<WTAudioManagerDelegate> delegate;

// 录音
@property (nonatomic, copy) NSString *recordPath;
@property (nonatomic, assign) NSTimeInterval recordDuration;
@property (nonatomic, assign) NSTimeInterval realRecordDuration;
@property (nonatomic, assign) WTAudioCategory audioCategory;

@property (nonatomic, assign) BOOL sessionActive;
@property (nonatomic, assign) BOOL sessionSwitching; // 状态切换中

+ (instancetype)sharedInstance;
- (void)destroy;

- (void)initAudioSession;

- (void)setSessionActive:(BOOL)sessionActive block:(FinishBlock)finishBlock;
- (void)activeSession:(WTAudioCategory)audioCategory block:(FinishBlock)finishBlock;
- (void)deactiveSession:(WTAudioCategory)audioCategory block:(FinishBlock)finishBlock;

- (BOOL)getPermission;

- (void)startRecord;
- (void)willCancelRecord;
- (void)stopRecord;

- (void)playWith:(NSData *)data finish:(CommonVoidBlock)completion;
- (void)stopPlay;

@end


//extern void UnityStartAudioRecord();
//extern void UnityStopAudioRecord();
//extern void UnityFirstBtnClick();






