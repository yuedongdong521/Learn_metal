//
//  YDDAlphaPlayerView.m
//  Learn_metal
//
//  Created by ydd on 2020/4/18.
//  Copyright © 2020 ydd. All rights reserved.
//

#import "YDDAlphaPlayerView.h"
#import "YDDAssetReader.h"
#import <AVFoundation/AVFoundation.h>
#import "AlphaFrameFilter.h"
#import "ISH264Player.h"

@interface YDDAlphaPlayerView ()
{
    CMSampleBufferRef _curSampleBuffer;
    CMTime _startTime;
    
    CVPixelBufferRef _newPixelbuffer;
    
    
}

@property (nonatomic, strong) ISH264Player *player;

@property (nonatomic, strong) YDDAssetReader *assetRender;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSDate *videoShowDate;
@property (nonatomic, assign) NSTimeInterval showDaution;

@property (nonatomic, assign) size_t videoWidth;
@property (nonatomic, assign) size_t videoHeight;

@property (nonatomic, assign) CGRect videoFrame;
@property (nonatomic, assign) CGRect alphaRect;

@property (nonatomic, strong)  AlphaFrameFilter *filter;

@end

@implementation YDDAlphaPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _player = [[ISH264Player alloc] initWithFrame:self.bounds];
        [self.layer addSublayer:_player];
     
        
        
        self.assetRender = [[YDDAssetReader alloc] initWithUrl:url];
        self.assetRender.runloop = YES;
        __weak typeof(self) weakself = self;
        self.assetRender.updatePlayerFps = ^(CGFloat fps) {
            if (fps > 0) {
                weakself.displayLink.frameInterval = 60 / fps;
            }
            
        };
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        self.displayLink.frameInterval = 60 / 20.0;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.displayLink setPaused:YES];
    }
    return self;
}

- (void)play
{
    [self.displayLink setPaused:NO];
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.player.frame = self.bounds;
}

- (VideoDataModel *)getVideoData
{
    return [self.assetRender readBuffer];
}


#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    /*
     CMTime outputItemTime = kCMTimeInvalid;
     
     // Calculate the nextVsync time which is when the screen will be refreshed next.
     CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
     
     outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
     
     if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
     CVPixelBufferRef pixelBuffer = NULL;
     pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
     
     [[self playerView] displayPixelBuffer:pixelBuffer];
     
     if (pixelBuffer != NULL) {
     CFRelease(pixelBuffer);
     }
     }
     */
    
    static int count = 0;
    count++;
    NSLog(@"cunt = %d", count);
    
    if (_curSampleBuffer) {
        NSDate *curDate = [NSDate date];
        NSTimeInterval  time = [curDate timeIntervalSinceDate:_videoShowDate];
        CMTime drutaion = CMSampleBufferGetOutputPresentationTimeStamp(_curSampleBuffer);
        _showDaution = CMTimeGetSeconds(drutaion);
        
        if (time >= _showDaution) {
            // 从LYAssetReader中读取图像数据
            CFRelease(_curSampleBuffer);
            _curSampleBuffer = nil;
            VideoDataModel *videoModel = [self getVideoData];
            _curSampleBuffer = videoModel.videoBuffer;
            _startTime = videoModel.startTime;
            CVPixelBufferRef buffer = [self useGPUCupPixelBuffer:CMSampleBufferGetImageBuffer(_curSampleBuffer)];
            [self.player playerForPixelBuffer:buffer];
        } else {
            NSLog(@"show daution : %f", _showDaution);
        }
    } else {
       
        VideoDataModel *videoModel = [self getVideoData];
        _curSampleBuffer = videoModel.videoBuffer;
        _videoShowDate = [NSDate dateWithTimeIntervalSinceNow:-CMTimeGetSeconds(videoModel.startTime)];
        
    }
}


- (CVPixelBufferRef)useGPUCupPixelBuffer:(CVPixelBufferRef)buffer
{
    /*
     如果要进行页面渲染，需要一个和OpenGL缓冲兼容的图像。用相机API创建的图像已经兼容，您可以马上映射他们进行输入。假设你从已有画面中截取一个新的画面，用作其他处理，你必须创建一种特殊的属性用来创建图像。对于图像的属性必须有kCVPixelBufferIOSurfacePropertiesKey 作为字典的Key.因此以下步骤不可省略
     */
    if (!buffer) {
        return NULL;
    }
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    
    
    if (_newPixelbuffer == NULL || _videoWidth != width || _videoHeight != height) {
        _videoWidth = width;
        _videoHeight = height;
        _newPixelbuffer = NULL;
        CGFloat playWidth = _videoWidth * 0.5;
        _videoFrame = CGRectMake(0, 0, playWidth, _videoHeight);
        _alphaRect = CGRectOffset(_videoFrame, _videoFrame.size.width, 0);;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(playWidth), kCVPixelBufferWidthKey, @(_videoHeight), kCVPixelBufferHeightKey, nil];
        OSStatus status = CVPixelBufferCreate(kCFAllocatorSystemDefault, playWidth, _videoHeight, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)options, &_newPixelbuffer);
        if (status != noErr) {
            NSLog(@"Crop CVPixelBufferCreate error %d",(int)status);
            return NULL;
        }
    }
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:buffer];
    
    CIImage *inputImage = [sourceImage imageByCroppingToRect:self.alphaRect];
    self.filter.inputImage = [inputImage imageByApplyingTransform:CGAffineTransformTranslate(CGAffineTransformIdentity, -_videoFrame.size.width, 0)];
    self.filter.maskImage = [sourceImage imageByCroppingToRect:_videoFrame];
    
    CIImage *outputImage = self.filter.outputImage;
    
    
    static CIContext *ciContext = nil;
    if (ciContext == nil) {
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        ciContext = [CIContext contextWithEAGLContext:eaglContext options:nil];
    }
    [ciContext render:outputImage toCVPixelBuffer:_newPixelbuffer];
    buffer = CVPixelBufferRetain(_newPixelbuffer);
    CVPixelBufferRelease(_newPixelbuffer);
    return _newPixelbuffer;
}

- (AlphaFrameFilter *)filter
{
    if (!_filter) {
        _filter = [[AlphaFrameFilter alloc] init];
    }
    return _filter;
}

@end
