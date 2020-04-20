//
//  YDDAssetReader.h
//  Learn_metal
//
//  Created by ydd on 2019/7/15.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoDataModel : NSObject

@property (nonatomic, assign, nullable) CMSampleBufferRef videoBuffer;

@property (nonatomic, assign) CMTime curTime;

@property (nonatomic, strong, nullable) NSData *audioData;

@property (nonatomic, assign) CMTime startTime;


@end

@interface YDDAssetReader : NSObject

@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) CGFloat fps;

@property (nonatomic, assign) BOOL runloop;

@property (nonatomic, copy) void(^updatePlayerFps)(CGFloat fps);

- (instancetype)initWithUrl:(NSURL *)url;

- (VideoDataModel *)readBuffer;


@end

NS_ASSUME_NONNULL_END
