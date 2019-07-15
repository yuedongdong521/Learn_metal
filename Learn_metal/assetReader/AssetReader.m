//
//  AssetReader.m
//  Learn_metal
//
//  Created by ydd on 2019/7/11.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "AssetReader.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AssetReader ()
{
    AVAssetReader *reader;
}

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, assign) BOOL shouldRepeat;


@end

@implementation AssetReader


- (instancetype)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
        _shouldRepeat = YES;
    }
    return self;
}

- (void)startProcessing {
    CMTime previousFrameTime = kCMTimeZero;
    CFTimeInterval previousActualFrameTime = CFAbsoluteTimeGetCurrent();
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    __weak typeof(self) weakself = self;
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            
            if (tracksStatus != AVKeyValueStatusLoaded) {
                return;
            }
            weakself.asset = inputAsset;
            [weakself processAsset];
        });
    }];
    
}
- (AVAssetReader*)createAssetReader{
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject:@(kCVPixelFormatType_32BGRA)
                       forKey:(id)kCVPixelBufferPixelFormatTypeKey];
   // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoTrackOutput];
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = ([audioTracks count] > 0);
    
    AVAssetReaderTrackOutput *readerAudioTrackOutput = nil;
    if (shouldRecordAudioTrack) {
        // This might need to be extended to handle movies with more than one audio track
        AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
        NSDictionary *dic = @{AVFormatIDKey : @(kAudioFormatLinearPCM), AVLinearPCMIsBigEndianKey : @(NO), AVLinearPCMIsFloatKey : @(NO), AVLinearPCMBitDepthKey :@(16)};
        readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:dic];
        readerAudioTrackOutput.alwaysCopiesSampleData = NO;
        [assetReader addOutput:readerAudioTrackOutput];
    }
    return assetReader;
    
}
- (void)processAsset{
    reader = [self createAssetReader];
    AVAssetReaderOutput *readerVideoTrackOutput = nil;
    AVAssetReaderOutput *readerAudioTrackOutput = nil;
    for( AVAssetReaderOutput *output in reader.outputs ) {
        if( [output.mediaType isEqualToString:AVMediaTypeAudio]) {
            readerAudioTrackOutput = output;
            
        } else if ([output.mediaType isEqualToString:AVMediaTypeVideo]) {
            readerVideoTrackOutput = output;
        }
    }
    if ([reader startReading] == NO) {
        NSLog(@"Error reading from file at URL: %@", self.url);
        return;
    }
    __unsafe_unretained AssetReader *weakSelf = self;
    while (reader.status == AVAssetReaderStatusReading) {
        [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
        if (readerAudioTrackOutput) {
            [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
            
        }
        
    }
    if (reader.status == AVAssetReaderStatusCompleted) {
        [reader cancelReading];
        if (_shouldRepeat) {
            reader = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
//                [self startProcessing];
            });
        } else {
//            [weakSelf endProcessing];
        }
    }
    
}
- (BOOL)readNextAudioSampleFromOutput:(AVAssetReaderOutput *)readerAudioTrackOutput;{
    if (reader.status == AVAssetReaderStatusReading) {
        CMSampleBufferRef audioSampleBufferRef = [readerAudioTrackOutput copyNextSampleBuffer];
        if (audioSampleBufferRef) {
            
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(audioSampleBufferRef);//取出数据
            // 返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);
            SInt16 sampleBytes[length];
            // 将数据放入数组
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes);
            // 将数据附加到data中
            NSData *audioData = [NSData dataWithBytes:sampleBytes length:length];
            if (_audioBuffer) {
                _audioBuffer(audioData);
            }
            
            CFRelease(audioSampleBufferRef);
            return YES;
        } else {
            
        }
        
    }
    return NO;
    
}
- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerVideoTrackOutput {
    if (reader.status == AVAssetReaderStatusReading) {
        CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
        if (sampleBufferRef) {
            
            
            
            CFRelease(sampleBufferRef);
            return YES;
            
        } else {
            
        }
        
    }
    return NO;
    
}
    



@end
