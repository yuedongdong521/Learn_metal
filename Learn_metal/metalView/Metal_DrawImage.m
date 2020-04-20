//
//  Metal_DrawImage.m
//  Learn_metal
//
//  Created by ydd on 2019/7/9.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "Metal_DrawImage.h"
#import <MetalKit/MetalKit.h>
#import "LYShaderTypes.h"


/**
 显示一张图片
 核心的内容包括：设置渲染管道、设置顶点和纹理缓存、简单的shader理解。
 */

@interface Metal_DrawImage ()<MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, assign) vector_uint2 viewporSize;
@property (nonatomic, strong) id <MTLRenderPipelineState> piplineState;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLBuffer> vertices;
@property (nonatomic, assign) NSInteger numVertices;
@property (nonatomic, strong) id <MTLTexture> texture;


@end

@implementation Metal_DrawImage

- (void)dealloc
{
    NSLog(@"dealloc %@", NSStringFromClass(self.class));
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.mtkView];
        self.viewporSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
        [self renderShader];
    }
    return self;
}

- (void)renderShader
{
    [self setupPipeline];
    [self setupVertex];
    [self setupTexture];
}

- (MTKView *)mtkView
{
    if (!_mtkView) {
        [[NSFileManager defaultManager] changeCurrentDirectoryPath:@"/"];
        // MTKView是MetalKit提供的一个View，用来显示Metal的绘制；
        _mtkView = [[MTKView alloc] initWithFrame:self.bounds];
        // MTLDevice代表GPU设备，提供创建缓存、纹理等的接口；
        _mtkView.device = MTLCreateSystemDefaultDevice();
        _mtkView.delegate = self;
        
        
    }
    return _mtkView;
}

/**
 设置渲染管道
 MTLRenderPipelineDescriptor是渲染管道的描述符，可以设置顶点处理函数、片元处理函数、输出颜色格式等；
 [device newCommandQueue]创建的是指令队列，用来存放渲染的指令；
 */
- (void)setupPipeline {
    
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:kMTLFUC_vertexShader];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:kMTLFUC_samplingShader];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    // 创建图形渲染通道, 耗性能操作不宜频繁调用
    self.piplineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
    // CommandQueue 是渲染指令队列, 保证渲染指令有序的提交到GPU
    self.commandQueue = [self.mtkView.device newCommandQueue];
    
}

- (void)setupVertex {
    static const LYVertex quadVertices[] = {
        {{  1.0, -1.0, 0.0, 1.0}, { 1.f, 1.f}},
        {{ -1.0, -1.0, 0.0, 1.0}, { 0.f, 1.f}},
        {{ -1.0,  1.0, 0.0, 1.0}, { 0.f, 0.f}},
        {{  1.0, -1.0, 0.0, 1.0}, { 1.f, 1.f}},
        {{ -1.0,  1.0, 0.0, 1.0}, { 0.f, 0.f}},
        {{  1.0,  1.0, 0.0, 1.0}, { 1.f, 0.f}},
    };
    // 创建顶点缓存
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    // 顶点个数
    self.numVertices = sizeof(quadVertices) / sizeof(LYVertex);
}


- (void)setupTexture {
    UIImage *image = [UIImage imageNamed:@"jintian.jpg"];
    NSUInteger widht = image.size.width;
    NSUInteger height = image.size.height;
//    widht *= 0.5;
//    height *= 0.5;
    
    // 纹理描述符
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width = widht;
    textureDescriptor.height = height;
    // 创建纹理
    self.texture = [self.mtkView.device newTextureWithDescriptor:textureDescriptor];
    // 纹理上传范围
    MTLRegion region = {{0, 0, 0}, {widht, height, 1}};

    Byte *imageBytes = [self loadImage:image];
    if (imageBytes) {
        [self.texture replaceRegion:region mipmapLevel:0 withBytes:imageBytes bytesPerRow:4 * image.size.width];
        free(imageBytes);
        imageBytes = NULL;
    }
   
}

- (Byte *)loadImage:(UIImage *)image
{
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    // 初始化二进制容器指针,   rgba数据共4 byte(字节)
    Byte *spriteData = (Byte *)calloc(width * height * 4, sizeof(size_t));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    
    return spriteData;
}

#pragma mark - MTKViewDelegate {
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    self.viewporSize = (vector_uint2){size.width, size.height};
}

// drawInMTKView:方法是MetalKit每帧的渲染回调，可以在内部做渲染的处理；
- (void)drawInMTKView:(MTKView *)view
{
    // 每次渲染都要单独创建一个CommandBuffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；
    // 同时也用来创建MTLRenderCommandEncoder
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if (renderPassDescriptor) {
        // 设置默认颜色
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f);
        // 编码绘制指令的Encoder
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        // 设置显示区域
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewporSize.x, self.viewporSize.y, -1.0, 1.0}];
        // 设置渲染管道 ,以保证顶点和片元两个shader会被调用
        [renderEncoder setRenderPipelineState:self.piplineState];
        // 设置顶点缓存
        [renderEncoder setVertexBuffer:self.vertices offset:0 atIndex:0];
        // 设置纹理
        [renderEncoder setFragmentTexture:self.texture atIndex:0];
        
        // 绘制
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];
        // 结束
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    // 提交
    [commandBuffer commit];
    
    
}

#pragma mark - }
@end
