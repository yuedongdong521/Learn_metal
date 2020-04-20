//
//  YDDAssetReader.m
//  Learn_metal
//
//  Created by ydd on 2019/7/15.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "YDDAssetReader.h"
#import <UIKit/UIKit.h>
#import "AlphaFrameFilter.h"

@implementation VideoDataModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _startTime = kCMTimeZero;
        _curTime = kCMTimeZero;
    }
    return self;
}

- (void)dealloc
{
}

@end


@interface YDDAssetReader ()

@property (nonatomic, strong) AVAssetReaderTrackOutput *readerVideoTrackOutput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *readerAudioTrackOutput;

@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) NSLock *readerLock;

@property (nonatomic, assign) BOOL isEnterBackgroud;

@property (nonatomic, strong) AVURLAsset *inputAsset;
@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, assign) CMTime curTime;
@property (nonatomic, assign) CMTime startTime;

@end

@implementation YDDAssetReader

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _videoUrl = url;
        //    videoUrl = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
        _readerLock = [[NSLock alloc] init];
        [self customInit];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackgroud:) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroud:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)appEnterBackgroud:(NSNotification *)notify
{
    _isEnterBackgroud = YES;
}

- (void)appEnterForegroud:(NSNotification *)notify
{
    _isEnterBackgroud = NO;
    if (_inputAsset) {
        [self createAssetReader:_curTime];
    }
    
}

- (void)customInit {
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    _inputAsset = [[AVURLAsset alloc] initWithURL:_videoUrl options:inputOptions];
    _duration = _inputAsset.duration;
    
    NSArray *keys = @[@"tracks", @"playable", @"duration"];
    __weak typeof(self) weakSelf = self;
    [_inputAsset loadValuesAsynchronouslyForKeys:keys completionHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSString *key in keys) {
                NSError *error = nil;
                AVKeyValueStatus keyStatus = [weakSelf.inputAsset statusOfValueForKey:key error:&error];
                NSLog(@"loadValue key : %@, status : %ld", key, (long)keyStatus);
                switch (keyStatus) {
                    case AVKeyValueStatusFailed:{
                        // failed
                        break;
                    }
                    case AVKeyValueStatusLoaded:{
                        // success
                        break;
                    }case AVKeyValueStatusCancelled:{
                        // cancelled
                        break;
                    }
                    default:
                        break;
                }
                
                if ([key isEqualToString:@"tracks"]) {
                    if (keyStatus != AVKeyValueStatusLoaded) {
                        NSLog(@"error %@", error);
                        return;
                    }
                    [self createAssetReader:kCMTimeZero];
                }
                
            }
            //            if (!weakInputAsset.playable) { // 不能播放
            //                return;
            //            }
        });
    }];
}

- (void)createAssetReader:(CMTime)curTime
{
    if (self.assetReader) {
        _assetReader = nil;
    }
    NSError *readerError = nil;
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.inputAsset error:&readerError];
    if (CMTimeCompare(kCMTimeZero, curTime) != 0) {
        self.assetReader.timeRange = CMTimeRangeMake(curTime, _duration);
    }
    self.startTime = curTime;
    if (!readerError && readerError.code != 0) {
        NSLog(@"readerError %@", readerError);
        return;
    }
    [self processWithAsset];
}


- (void)processWithAsset
{
    [_readerLock lock];
    NSLog(@"processWithAsset");
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVAssetTrack *videoTrack = [[self.inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    _fps = videoTrack.nominalFrameRate;
    _readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:outputSettings];
    _readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [self.assetReader addOutput:_readerVideoTrackOutput];
    
    if (self.updatePlayerFps) {
        self.updatePlayerFps(_fps);
    }
    
    
    NSArray *audioTracks = [self.inputAsset tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = ([audioTracks count] > 0);
    
    
    if (shouldRecordAudioTrack) {
        // This might need to be extended to handle movies with more than one audio track
        AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
        NSDictionary *dic = @{AVFormatIDKey : @(kAudioFormatLinearPCM), AVLinearPCMIsBigEndianKey : @(NO), AVLinearPCMIsFloatKey : @(NO), AVLinearPCMBitDepthKey :@(16)};
        _readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:dic];
        _readerAudioTrackOutput.alwaysCopiesSampleData = NO;
        [self.assetReader addOutput:_readerAudioTrackOutput];
    }
    
    if ([self.assetReader startReading] == NO)
    {
        NSLog(@"Error reading from file at URL: %@", self.inputAsset);
    }
    [_readerLock unlock];
}



- (VideoDataModel *)readBuffer {
    if (_isEnterBackgroud) {
        return nil;
    }
    if (self.assetReader.status != AVAssetReaderStatusReading) {
        return nil;
    }
    
    [_readerLock lock];
    
    VideoDataModel *videoData = [[VideoDataModel alloc] init];
    
    CMSampleBufferRef videoBuffer = nil;
    if (_readerVideoTrackOutput) {
        videoBuffer = [_readerVideoTrackOutput copyNextSampleBuffer];
        
        
        _curTime = CMSampleBufferGetOutputPresentationTimeStamp(videoBuffer);
    }
    NSData *audioData = nil;
    if (_readerAudioTrackOutput) {
        CMSampleBufferRef audioBuffer = [_readerAudioTrackOutput copyNextSampleBuffer];
        //        NSLog(@"audiobuffer %@", audioBuffer);
        if (audioBuffer) {
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(audioBuffer);//取出数据
            // 返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);
            SInt16 sampleBytes[length];
            // 将数据放入数组
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes);
            // 将数据附加到data中
            audioData = [NSData dataWithBytes:sampleBytes length:length];
            //            free(sampleBytes);
            CMSampleBufferInvalidate(audioBuffer);  //销毁
            CFRelease(audioBuffer);
        }
    }
    
    if (self.assetReader && self.assetReader.status == AVAssetReaderStatusCompleted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"customInit");
            self.readerVideoTrackOutput = nil;
            self.readerAudioTrackOutput = nil;
            if (self.runloop) {
                [self createAssetReader:kCMTimeZero];
            }
        });
    }
    
    videoData.videoBuffer = videoBuffer;
    videoData.audioData = audioData;
    videoData.curTime = _curTime;
    videoData.startTime = _startTime;
    
    [_readerLock unlock];
    
    
  
    return videoData;
}

- (NSData *)getRecorderDataFromURL:(NSURL *)url {
    
    NSMutableData *data = [[NSMutableData alloc]init];     //用于保存音频数据
    AVAsset *asset = [AVAsset assetWithURL:url];           //获取文件
    
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error]; //创建读取
    if (!reader) {
        
        NSLog(@"%@",[error localizedDescription]);
    }
    
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//从媒体中得到声音轨道
    //读取配置
    NSDictionary *dic   = @{AVFormatIDKey            :@(kAudioFormatLinearPCM),
                            //                            AVLinearPCMIsBigEndianKey:@NO,
                            //                            AVLinearPCMIsFloatKey    :@NO,
                            //                            AVLinearPCMBitDepthKey   :@(16)
                            };
    //读取输出，在相应的轨道和输出对应格式的数据
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
    //赋给读取并开启读取
    [reader addOutput:output];
    [reader startReading];
    
    //读取是一个持续的过程，每次只读取后面对应的大小的数据。当读取的状态发生改变时，其status属性会发生对应的改变，我们可以凭此判断是否完成文件读取
    while (reader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef  sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
        if (sampleBuffer) {
            
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);   //返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length];                 //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);  //销毁
            CFRelease(sampleBuffer);                 //释放
        }
    }
    if (reader.status == AVAssetReaderStatusCompleted) {
        
        //        self.audioData = data;
        
    }else{
        
        NSLog(@"获取音频数据失败");
        return nil;
    }
    
    //开始绘制波形图，重写了draw方法
    //    [self setNeedsDisplay];
    return data;
    
    
}


//-(NSData *) convertAudioSmapleBufferToPcmData:(CMSampleBufferRef) audioSample{
//
//    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(pcmData));
//
//    //获取CMBlockBufferRef
//    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(pcmData);
//    //获取pcm数据大小
//    size_t length = CMBlockBufferGetDataLength(blockBufferRef);
//
//    //分配空间
//    char buffer[length];
//    //直接将数据copy至我们自己分配的内存中
//    CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
//
//    if ((inAudioStreamBasicDescription.mFormatFlags & kAudioFormatFlagIsBigEndian) == kAudioFormatFlagIsBigEndian)
//    {
//        for (int i = 0; i < length; i += 2)
//        {
//            char tmp = buffer[i];
//            buffer[i] = buffer[i+1];
//            buffer[i+1] = tmp;
//        }
//    }
//
//    uint32_t ch = inAudioStreamBasicDescription.mChannelsPerFrame;
//    uint32_t fs = inAudioStreamBasicDescription.mSampleRate;
//
//    //返回数据
//    return [NSData dataWithBytesNoCopy:buffer length:audioDataSize];
//}






@end
