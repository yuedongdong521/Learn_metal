//
//  LYAssetReader.h
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 2018/5/25.
//  Copyright © 2018年 loyinglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LYAssetReader : NSObject

@property (nonatomic, assign, readonly) CMTime duration;

@property (nonatomic, assign) BOOL runloop;

- (instancetype)initWithUrl:(NSURL *)url;

- (CMSampleBufferRef)readBufferBlock:(void(^)(NSData *audioData))block;
@end
