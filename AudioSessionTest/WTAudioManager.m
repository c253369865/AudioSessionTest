//
//  WTAudioSession.m
//  WeToo
//
//  Created by TerryChao on 2016/10/18.
//  Copyright © 2016年 LoveOrange. All rights reserved.
//

#import "WTAudioManager.h"
//#import "WTStorageConfig.h"

#define WT_TICK   NSDate *startTime = [NSDate date];
#define WT_TOCK(info)   NSLog(@"%@ -> Time: %f", info,-[startTime timeIntervalSinceNow]);

@interface WTAudioManager () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *recorderTimer;

@property (nonatomic, copy) NSString *originSesstionCategory;
@property (nonatomic, copy) NSString *originSesstionMode;
@property (nonatomic, assign) AVAudioSessionCategoryOptions originSesstionCategoryOptions;

@property (nonatomic, strong) dispatch_queue_t audioSessionQueue;

@property (nonatomic, strong) AVAudioPlayer *soundPlayer;
@property (nonatomic, copy) CommonVoidBlock playCompletion;

@end

@implementation WTAudioManager

static WTAudioManager *_sharedInstance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [WTAudioManager new];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.recordDuration = 0;
        self.realRecordDuration = -1;
        self.sessionSwitching = NO;
        self.sessionActive = NO;
        self.audioCategory = WTAudioCategoryNil;
        self.audioSessionQueue = dispatch_queue_create("WTAudioSession.queue", DISPATCH_QUEUE_CONCURRENT);
        self.recordPath = [NSString stringWithFormat:@"%@/WTAudioRecord.m4a", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    }
    return self;
}

- (void)destroy
{
    [self stopRecord];
    _recorder = nil;
    _soundPlayer = nil;
    _playCompletion = nil;
}

#pragma  mark - Session

- (void)initAudioSession
{
//    return;
    NSLog(@"WTAudioManager initAudioSession");
    WT_TICK
    WT_TOCK(@"WTAudioManager initAudioSession nothing")
    
    dispatch_async(_audioSessionQueue, ^{
        WT_TOCK(@"WTAudioManager initAudioSession begin init")
        // 记录原始的
        _originSesstionCategory = [[AVAudioSession sharedInstance] category];
        _originSesstionMode = [[AVAudioSession sharedInstance] mode];
        _originSesstionCategoryOptions = [[AVAudioSession sharedInstance] categoryOptions];
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride),  &audioRouteOverride);
        #pragma clang diagnostic pop
        WT_TOCK(@"WTAudioManager initAudioSession RouteOverride")
        
        NSLog(@"WTAudioManager initAudioSession finished.");
        WT_TOCK(@"WTAudioManager initAudioSession")
        NSLog(@"----------------------------------------------");
    });
}

- (void)setSessionActive:(BOOL)sessionActive block:(FinishBlock)finishBlock
{
    WT_TICK
    NSLog(@"WTAudioManager setSessionActive status = %@", sessionActive ? @"YES" : @"NO" );
    
    if (_sessionActive == sessionActive) {
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeSueecss);
        }
        return;
    }
    
    if (_sessionSwitching) {
        NSLog(@"WTAudioManager setSessionActive is setting ...");
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeFail);
        }
        return;
    }
    _sessionSwitching = YES;
    
    if (_sessionActive == sessionActive) {
        NSLog(@"WTAudioManager setSessionActive status = the same.");
        _sessionSwitching = NO;
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeSueecss);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_audioSessionQueue, ^{
        NSLog(@"WTAudioManager setSessionActive thread %@, %d", [NSThread currentThread], [NSThread isMainThread]);
        NSError *sessionError = nil;
        if (sessionActive) {
            [[AVAudioSession sharedInstance] setActive:sessionActive error:&sessionError];
        }
        else {
            [[AVAudioSession sharedInstance] setActive:sessionActive withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&sessionError];
        }
        if (sessionError) {
            WT_TOCK(@"WTAudioManager setSessionActive = %@ fail.")
            NSLog(@"WTAudioManager setSessionActive %@", sessionError);
            weakSelf.sessionSwitching = NO;
            if (finishBlock) {
                finishBlock(WTAudioSessionCodeFail);
            }
            return;
        }
        WT_TOCK(@"WTAudioManager setSessionActive ok")
        weakSelf.sessionSwitching = NO;
        weakSelf.sessionActive = sessionActive;
        
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeSueecss);
        }
    });
}

// 为什么启动的时候马上调用,会停止音乐播放.
- (void)activeSession:(WTAudioCategory)audioCategory block:(FinishBlock)finishBlock
{    
    if (self.audioCategory == audioCategory && self.sessionActive) {
        NSLog(@"WTAudioManager activeSession the same.");
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeSueecss);
        }
        return;
    }
    
    if (self.audioCategory != audioCategory) {
        self.audioCategory = audioCategory;
        
        AVAudioSessionCategoryOptions options;
        switch (audioCategory) {
            case WTAudioCategoryRecordWithoutMusic:
                options = AVAudioSessionCategoryOptionDefaultToSpeaker;
                break;
            case WTAudioCategoryRecordWithMusic:
                options = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker;
                break;
            case WTAudioCategoryPlayWithoutMusic:
                options = AVAudioSessionCategoryOptionDefaultToSpeaker;
                break;
            default:
                options = AVAudioSessionCategoryOptionMixWithOthers;
                break;
        }
        
        NSError *sessionError = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:&sessionError];
        if (sessionError) {
            NSLog(@"WTAudioManager activeSession setCategory sessionError %@", sessionError);
            if (finishBlock) {
                finishBlock(WTAudioSessionCodeFail);
            }
        }
    }
    
    if (self.sessionActive != YES) {
        [self setSessionActive:YES block:finishBlock];
    }
    else {
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeSueecss);
        }
        NSLog(@"WTAudioManager activeSession finished.");
    }
}

- (void)deactiveSession:(WTAudioCategory)audioCategory block:(FinishBlock)finishBlock
{
    /*
    WT_TICK
    BOOL isOtherAudioPlaying = [[AVAudioSession sharedInstance] isOtherAudioPlaying];
    NSLog(@"WTAudioManager deactiveSession isOtherAudioPlaying %@", isOtherAudioPlaying ? @"YES" : @"NO");
    if (isOtherAudioPlaying) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf setSessionActive:NO block:finishBlock];
        });
    }
    else {
        NSLog(@"WTAudioManager deactiveSessionFromRecord finished.");
        WT_TOCK(@"WTAudioManager deactiveSession")
        
        if (finishBlock) {
            finishBlock(WTAudioSessionCodeSueecss);
        }
    }
    */
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf setSessionActive:NO block:finishBlock];
    });
}

- (void)playWithSpeaker
{
    WT_TICK
    NSLog(@"WTAudioManager playWithSpeaker begin.");
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride),  &audioRouteOverride);
    #pragma clang diagnostic pop
    WT_TOCK(@"WTAudioManager playWithSpeaker finish.");
}

#pragma mark - Permission

- (BOOL)getPermission
{
    // 获取麦克风权限
    __block BOOL _hasPermission = YES;
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL available) {
        if (!available)
        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[[UIAlertView alloc] initWithTitle:@"无法录音"
//                                            message:@"请在“设置-隐私-麦克风”中允许访问麦克风。"
//                                           delegate:nil
//                                  cancelButtonTitle:@"确定"
//                                  otherButtonTitles:nil]
//                 show];
//            });
//            NSString *appName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
//            UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"设置麦克风权限"
//                                                                message:[NSString stringWithFormat:@"请在设备的\"设置-隐私-麦克风\"选项中，允许%@访问你的麦克风", appName]
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"就不"
//                                                      otherButtonTitles:@"设置", nil];
//            [alertView show];
//            [alertView.rac_buttonClickedSignal subscribeNext:^(id x) {
//                if ([x integerValue] == 1) {
//                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
//                        [[UIApplication sharedApplication] openURL:url];
//                    }
//                }
//            }];
        }
        _hasPermission = available;
    }];
    
    return _hasPermission;
}


#pragma mark - Record

- (void)startRecord
{
    if ([self getPermission]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startRecording];
        });
    }
}

- (void)startRecording
{
//    [self activeSession];
    
    if (![self initRecord])
    {
//        [WTToastView show:@"初始化录音机失败"];
        return;
    }
    
    [self.recorder record];
    
    self.recordDuration = 0;
    self.realRecordDuration = -1;
    
    self.recorderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onRecording) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.recorderTimer forMode:NSRunLoopCommonModes];
    
    if ([self.delegate respondsToSelector:@selector(startRecord)]) {
        [self.delegate startRecord];
    }
    
    NSLog(@"WTAudioManager start record at %@", self.recordPath);
}


- (BOOL)initRecord
{
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    

//    NSString *strUrl = [NSString stringWithFormat:@"%@/WTAudioRecord.aac", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    NSURL *url = [NSURL fileURLWithPath:self.recordPath];
//    self.recordPath = strUrl;
    
    //初始化
    NSError *error = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&error];
    // 这样写不行?why?
//    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&error];
    _recorder.delegate = self;
    if (error) {
        NSLog(@"WTAudioManager 录音机初始化失败 : %@", error);
        return NO;
    }
    [self delRecordData];
    
    if ([self.recorder prepareToRecord])
    {
        return YES;
    }
    
    return NO;
}

- (void)onRecording
{
    self.recordDuration++;
    
    if (self.recordDuration-1 >= 50)
    {
        [self stopTimer];
        [self stopRecord];
    }
    
    NSTimeInterval duration = self.recorder.currentTime;
    self.realRecordDuration = (NSInteger)(duration + 0.5);
}

// 取消录制
- (void)willCancelRecord
{
    [self stopTimer];
    
    [self.recorder stop];
    [self delRecordData];
    
    self.recordDuration = 0;
    self.realRecordDuration = -1;
    
    if ([self.delegate respondsToSelector:@selector(willCancelRecord)]) {
        [self.delegate willCancelRecord];
    }
}

- (void)delRecordData
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.recorder.url.path])
    {
        if (!self.recorder.recording)
        {
            NSData *audioData = [NSData dataWithContentsOfFile:self.recorder.url.path];
            [self.recorder deleteRecording];
            NSLog(@"WTAudioManager delRecordData audioData -> length %lu", audioData.length);
            NSLog(@"WTAudioManager delRecordData sucess. %@", @"");
            return;
        }
    };
    NSLog(@"WTAudioManager delRecordData fail. %@", self.recordPath);
}

- (void)stopTimer
{
    [self.recorderTimer invalidate];
    self.recorderTimer = nil;
}

- (void)stopRecord
{
    [self stopTimer];
    [_recorder stop];
    
    // 录音太短
    if (self.realRecordDuration < 0.5)
    {
        if ([self.delegate respondsToSelector:@selector(willCancelRecord)]) {
            [self.delegate willCancelRecord];
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(stopRecord:duration:)]) {
            [self.delegate stopRecord:self.recordPath duration:self.realRecordDuration];
        }
    }
    
    
    NSData *audioData = [NSData dataWithContentsOfFile:self.recordPath];
    NSLog(@"WTAudioManager audioData-> length %lu", audioData.length);
    
    self.recordDuration = 0;
    self.realRecordDuration = -1;
    
    [_recorder stop];
//    [_recorder prepareToRecord];
    _recorder = nil;
    
    NSLog(@"WTAudioManager stop record.");
}

#pragma mark - Play

- (void)playWith:(NSData *)data finish:(CommonVoidBlock)completion
{
    [self stopPlay];
    
//    [self activeSession:^WTAudioSessionCode{
//        
//    }];
    NSLog(@"WTAudioManager playWith audio data.length = %lu, _soundPlayer = %@", data.length, _soundPlayer);
    
    NSError *playerError = nil;
    _soundPlayer = [[AVAudioPlayer alloc] initWithData:data error:&playerError];
    _playCompletion = completion;
    
    if (_soundPlayer)
    {
        _soundPlayer.delegate = self;
        [_soundPlayer prepareToPlay];
        [_soundPlayer play];
    }
    else
    {
        NSLog(@"WTAudioManager Error creating player: %@", [playerError description]);
        if (_playCompletion)
        {
            _playCompletion();
        }
    }
    
    
}

- (void)stopPlay
{
    if (_playCompletion)
    {
        _playCompletion();
        _playCompletion = nil;
    }
    
    if (_soundPlayer)
    {
        if (_soundPlayer.isPlaying)
        {
            [_soundPlayer stop];
            [_soundPlayer prepareToPlay];
        }
        
        _soundPlayer.delegate = nil;
        _soundPlayer = nil;
    }
    
    NSLog(@"WTAudioManager stopPlay audio, _soundPlayer = %@", _soundPlayer);
}

#pragma mark - AVAudioRecorderDelegate

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"recorder = %@, flag = %@", recorder, flag ? @"YES" : @"NO");
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
{
     NSLog(@"recorder = %@, error = %@", recorder, error);
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"WTAudioManager audioPlayerDidFinishPlaying, player = %@, flag = %@", player, flag ? @"YES" : @"NO");
    
//    [player stop];
//    [player prepareToPlay];
    
    [self stopPlay];
    
//    [self setSessionActive:NO block:nil];
    [self deactiveSession:WTAudioCategoryPlayWithoutMusic block:nil];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    NSLog(@"WTAudioManager audioPlayerDecodeErrorDidOccur, player = %@, error = %@", player, error);
    
//    [player stop];
//    [player prepareToPlay];
    
    [self stopPlay];
//    [self setSessionActive:NO block:nil];
    [self deactiveSession:WTAudioCategoryPlayWithoutMusic block:nil];
}

@end
//
//
//#pragma mark - U3D Callbacks
//
//void UnityStartAudioRecord()
//{
//#if USING_U3D
//    [[WTAudioManager sharedInstance] activeSessionRecord:^(WTAudioSessionCode code) {
//        if (code == WTAudioSessionCodeSueecss) {
//            [[WTAudioManager sharedInstance] startRecord];
//        }
//    }];
//#endif
//}
//
//void UnityStopAudioRecord()
//{
//#if USING_U3D
//    [[WTAudioManager sharedInstance] stopRecord];
//    NSString *audioPath = [[WTAudioManager sharedInstance] recordPath];
//    UnitySendMessage("CaptureManager", "OnGetAudioPath", audioPath.UTF8String);
//#endif
//}
//
//void UnityFirstBtnClick()
//{
//    
//}
//


