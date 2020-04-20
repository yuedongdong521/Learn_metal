//
//  Metal_CaptureView.m
//  Learn_metal
//
//  Created by ydd on 2019/7/10.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "Metal_CaptureView.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>


@interface Metal_CaptureView ()<AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate>
{
    dispatch_queue_t _videoOutputQueue;
}

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;


@property (nonatomic, strong) MTKView *mtkView;

@property (nonatomic, assign) CVMetalTextureCacheRef outputTextureCache; //output
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;

@property (nonatomic, assign) float sigaBlur;

@end


@implementation Metal_CaptureView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc
{
    NSLog(@"dealloc %@", NSStringFromClass(self.class));
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.sigaBlur = 1;
        [self addSubview:self.mtkView];
        self.commandQueue = [self.mtkView.device newCommandQueue];
        CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_outputTextureCache);
        
        [self setupCapture];
        [self.captureSession startRunning];
        [self setupSlider];
    }
    return self;
}

- (void)setupSlider
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, self.bounds.size.height - 100, self.bounds.size.width - 40, 50)];
    slider.value = 0.2;
    slider.minimumValue = 0;
    slider.maximumValue = 1;
    slider.thumbTintColor = [UIColor whiteColor];
    slider.thumbTintColor = [UIColor redColor];
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:slider];
}

- (void)sliderAction:(UISlider *)slider
{
    float value = slider.value * 5;
    self.sigaBlur = value;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef tmpTexture = NULL;
    // 如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _outputTextureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    if(status == kCVReturnSuccess)
    {
        self.mtkView.drawableSize = CGSizeMake(width, height);
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        CFRelease(tmpTexture);
    }
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)drawInMTKView:(MTKView *)view
{
    if (self.texture) {
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer]; // 创建指令缓冲
        id<MTLTexture> drawingTexture = view.currentDrawable.texture; // 把MKTView作为目标纹理
        
        MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.mtkView.device sigma:self.sigaBlur]; // 这里的sigma值可以修改，sigma值越高图像越模糊
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture]; // 把摄像头返回图像数据的原始数据
        
        [commandBuffer presentDrawable:view.currentDrawable]; // 展示数据
        [commandBuffer commit];
        
        self.texture = NULL;
    }
}



- (void)setupCapture
{
    if ([self.captureSession canAddInput:self.deviceInput]) {
        [self.captureSession addInput:self.deviceInput];
    }
    if ([self.captureSession canAddOutput:self.videoOutput]) {
        [self.captureSession addOutput:self.videoOutput];
    }
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _captureSession;
}

- (AVCaptureDeviceInput *)deviceInput
{
    if (!_deviceInput) {
        _deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self getCaptureDeviceWithPosition:AVCaptureDevicePositionFront] error:nil];
    }
    return _deviceInput;
}

- (AVCaptureVideoDataOutput *)videoOutput
{
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:NO];
        // 这里设置格式为BGRA，而不用YUV的颜色空间，避免使用Shader转换
        [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        _videoOutputQueue = dispatch_queue_create("videodataQueue", DISPATCH_QUEUE_SERIAL);
        [_videoOutput setSampleBufferDelegate:self queue:_videoOutputQueue];
    }
    return _videoOutput;
}


- (AVCaptureDevice *)getCaptureDeviceWithPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[
                                                                                                                        AVCaptureDeviceTypeBuiltInDualCamera,
                                                                                                                           AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    __block AVCaptureDevice *device = nil;
    [discoverySession.devices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.position == position) {
            device = obj;
            *stop = YES;
        }
    }];
    return device;
}

- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.bounds];
        _mtkView.device = MTLCreateSystemDefaultDevice();
        _mtkView.delegate = self;
        _mtkView.framebufferOnly = NO;
    }
    return _mtkView;
}

@end
