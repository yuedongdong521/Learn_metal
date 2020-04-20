//
//  AudioPlayer.m
//  Learn_metal
//
//  Created by ydd on 2019/7/12.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioPlayer ()

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, assign) BOOL addObserver;

@end

@implementation AudioPlayer

- (instancetype)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.url = url;
        [self commonInit];
    }
    return self;
}



- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}


- (void)commonInit
{
    if (!_addObserver) {
        _addObserver = YES;
        [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    
}

- (AVPlayer *)player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        _player.volume = 1;
    }
    return _player;
}


- (void)setUrl:(NSURL *)url
{
    _url = url;
    [self pause];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:_url];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        NSLog(@"status : %ld", (long)status);
    }
}

- (void)playUrl:(NSURL *)url
{
    self.url = url;
    [self play];
}

- (void)play
{
    if (!_playing) {
        [_player play];
    }
}

- (void)pause
{
    if (_playing) {
        _playing = NO;
        [_player pause];
    }
}

- (void)destory
{
    if (_player) {
        [_player pause];
        if (_addObserver) {
            [_player removeObserver:self forKeyPath:@"status"];
        }
        _player = nil;
    }
}
- (void)playDidFinish:(NSNotification *)notify
{
    AVPlayerItem *playerItem = (AVPlayerItem *)notify.object;
    if (playerItem) {
        __weak typeof(self) weakself = self;
        [playerItem seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            self.playing = NO;
            if (weakself.runloop) {
                [weakself play];
            }
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
