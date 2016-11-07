//
//  AudioSessionTestViewController.m
//  AudioSessionTest
//
//  Created by TerryChao on 2016/10/24.
//  Copyright © 2016年 czh. All rights reserved.
//

#import "AudioSessionTestViewController.h"
#import "WTAudioManager.h"
#import "WTVideoPlayerView.h"
#import "ZHAVPlayerView.h"

@interface AudioSessionTestViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet WTVideoPlayerView *videoPlayView;

@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) ZHAVPlayerView *playerView;

@end

@implementation AudioSessionTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Audio Session";
    
    self.imageView.animationImages = @[[UIImage imageNamed:@"yellow_being"],[UIImage imageNamed:@"yellow_being_1"]];
    self.imageView.animationDuration = 0.3;
    [self.imageView startAnimating];
    
    self.videoPlayView.contentMode = UIViewContentModeScaleAspectFill;
    self.videoPlayView.backgroundColor = [UIColor clearColor];
    
//    self.videoPlayView.hidden = YES;
//    [self addPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)addPlayer
{
    NSLog(@"mainScreen %@", NSStringFromCGRect([[UIScreen mainScreen] bounds]));
    NSLog(@"view %@", NSStringFromCGRect(self.view.bounds));
    
    self.playerView = [[ZHAVPlayerView alloc] initWithFrame:self.videoPlayView.frame];
    [self.playerView setVolume:0.3];
    [self.playerView setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:self.playerView];
}


- (IBAction)initSessionClick:(id)sender {
}

- (IBAction)recordClick:(id)sender {
    [[WTAudioManager sharedInstance] activeSession:WTAudioCategoryRecordWithoutMusic block:^(WTAudioSessionCode code) {
        if (code == WTAudioSessionCodeSueecss) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [[WTAudioManager sharedInstance] startRecord];
//            });
            [[WTAudioManager sharedInstance] startRecord];
        }
    }];
}

- (IBAction)stopRecordClick:(id)sender {
    [[WTAudioManager sharedInstance] stopRecord];
    [[WTAudioManager sharedInstance] deactiveSession:WTAudioCategoryRecordWithoutMusic block:nil];
}

- (IBAction)playAudioClick:(id)sender {
    [[WTAudioManager sharedInstance] activeSession:WTAudioCategoryPlayWithoutMusic block:^(WTAudioSessionCode code) {
        if (code == WTAudioSessionCodeSueecss) {
            NSString *path = [[WTAudioManager sharedInstance] recordPath];
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSLog(@"audio length %lu", data.length);
            [[WTAudioManager sharedInstance] playWith:data finish:^{
                NSLog(@"play audio end.");
            }];
        }
    }];
}
- (IBAction)stopPlayAudioClick:(id)sender {
    [[WTAudioManager sharedInstance] stopPlay];
    [[WTAudioManager sharedInstance] deactiveSession:WTAudioCategoryPlayWithoutMusic block:nil];
}

- (IBAction)playVideoClick:(id)sender {
    __weak typeof(self) weakSelf = self;
    [[WTAudioManager sharedInstance] activeSession:WTAudioCategoryPlayWithoutMusic block:^(WTAudioSessionCode code) {
        if (code == WTAudioSessionCodeSueecss) {
            NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"start" ofType:@"mp4"]];
            AVAsset *asset = [AVAsset assetWithURL:url];
            weakSelf.playerItem = [AVPlayerItem playerItemWithAsset:asset];
            weakSelf.videoPlayView.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            [weakSelf.videoPlayView.player play];
        }
    }];
}
- (IBAction)stopVideoClick:(id)sender {
    [self playbackFinished:nil];
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    [self removeObserverFromPlayerItem:_playerItem];
    _playerItem = playerItem;
    [self addObserverToPlayerItem:_playerItem];
}

- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    }
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    }
}

- (void)playbackFinished:(NSNotification *)notification
{
    [self.videoPlayView.player pause];
    //    [self removeObserverFromPlayerItem:_playerItem];
    _playerItem = nil;
    //self.videoPlayView.player = nil;
    NSLog(@"isOtherAudioPlaying = %@", [[AVAudioSession sharedInstance] isOtherAudioPlaying] ? @"YES" : @"NO");
    NSLog(@"player=%@, status=%lu,_playerItem=%@",self.videoPlayView.player, self.videoPlayView.player.status,_playerItem);
    [[WTAudioManager sharedInstance] deactiveSession:WTAudioCategoryPlayWithoutMusic block:nil];
}

- (void)goodCode
{
    [[WTAudioManager sharedInstance] setSessionActive:NO block:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
